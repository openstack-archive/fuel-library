# RUN: neut_vlan.ceph.ceil-primary-controller.overridden_ssl ubuntu
# RUN: neut_vlan.ceph.controller-ephemeral-ceph ubuntu
# RUN: neut_vlan.ironic.controller ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-controller ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl ubuntu

require 'spec_helper'
require 'shared-examples'
manifest = 'murano/cfapi.pp'

describe manifest do
  shared_examples 'catalog' do

    let(:tenant) { Noop.hiera_structure('access/tenant', 'admin') }

    let(:network_scheme) do
      Noop.hiera_hash 'network_scheme'
    end

    let(:prepare) do
      Noop.puppet_function 'prepare_network_config', network_scheme
    end

    let(:public_ip) do
      Noop.hiera 'public_vip'
    end

    let(:management_ip) do
      Noop.hiera 'management_vip'
    end

    let(:bind_address) do
      prepare
      Noop.puppet_function 'get_network_role_property', 'murano/cfapi', 'ipaddr'
    end

    let(:public_ssl) { Noop.hiera_structure('public_ssl/services') }

    let(:bind_port) { '8083' }

    let(:ssl_hash) { Noop.hiera_hash 'use_ssl', {} }

    let (:murano_cfapi_protocol){
      Noop.puppet_function 'get_ssl_property', ssl_hash, {}, 'murano',
        'internal', 'protocol', 'http'
    }

    let (:murano_cfapi_address){
      Noop.puppet_function 'get_ssl_property', ssl_hash, {}, 'murano',
        'internal', 'hostname',
        [Noop.hiera('service_endpoint', ''), Noop.hiera('management_vip')]
    }

    let (:murano_cfapi_url){
      "#{murano_cfapi_protocol}://#{murano_cfapi_address}:#{bind_port}"
    }

    if Noop.hiera_structure('use_ssl', false)
      public_auth_protocol = 'https'
      public_auth_address = Noop.hiera_structure('use_ssl/keystone_public_hostname')
    elsif Noop.hiera_structure('public_ssl/services', false)
      public_auth_protocol = 'https'
      public_auth_address = Noop.hiera_structure('public_ssl/hostname')
    else
      public_auth_protocol = 'http'
      public_auth_address = Noop.hiera('public_vip')
    end

    #############################################################################

    enable = Noop.hiera_structure('murano-cfapi/enabled')

    context 'if murano-cfapi is enabled', :if => enable do
      it 'should declare murano::cfapi class correctly' do
        should contain_class('murano::cfapi').with(
                   'tenant'    => tenant,
                   'bind_port' => bind_port,
                   'bind_host' => bind_address,
                   'auth_url'  => "#{public_auth_protocol}://#{public_auth_address}:5000/v3",
               )
      end

      it {
        if Noop.hiera('external_lb', false)
          url = murano_cfapi_url
          provider = 'http'
        else
          url = 'http://' + management_ip + ':10000/;csv'
          provider = Puppet::Type.type(:haproxy_backend_status).defaultprovider.name
        end
        should contain_haproxy_backend_status('murano-cfapi').with(
          :url      => url,
          :provider => provider
        )
      }
    end

  end

  test_ubuntu_and_centos manifest
end
