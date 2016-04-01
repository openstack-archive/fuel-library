# RUN: neut_tun.ceph.murano.sahara.ceil-controller ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-primary-controller ubuntu
# RUN: neut_tun.ironic-primary-controller ubuntu
# RUN: neut_tun.l3ha-primary-controller ubuntu
# RUN: neut_vlan.ceph-primary-controller ubuntu
# RUN: neut_vlan.dvr-primary-controller ubuntu
# RUN: neut_vlan.murano.sahara.ceil-controller ubuntu
# RUN: neut_vlan.murano.sahara.ceil-primary-controller ubuntu

require 'spec_helper'
require 'shared-examples'
manifest = 'murano/keystone.pp'

describe manifest do
  shared_examples 'catalog' do

    let(:service_endpoint) { Noop.hiera 'service_endpoint' }
    let(:network_scheme) { Noop.hiera_hash 'network_scheme' }
    api_bind_port = '8082'

    internal_protocol = 'http'
    internal_address = Noop.hiera('management_vip')
    admin_protocol = 'http'
    admin_address = internal_address

    if Noop.hiera_structure('use_ssl', false)
      public_protocol = 'https'
      public_address = Noop.hiera_structure('use_ssl/murano_public_hostname')
      internal_protocol = 'https'
      internal_address = Noop.hiera_structure('use_ssl/murano_internal_hostname')
      admin_protocol = 'https'
      admin_address = Noop.hiera_structure('use_ssl/murano_admin_hostname')
    elsif Noop.hiera_structure('public_ssl/services')
      public_protocol = 'https'
      public_address = Noop.hiera_structure('public_ssl/hostname')
    else
      public_protocol = 'http'
      public_address = Noop.hiera 'public_vip'
    end
    public_url = "#{public_protocol}://#{public_address}:#{api_bind_port}"
    internal_url = "#{internal_protocol}://#{internal_address}:#{api_bind_port}"
    admin_url = "#{admin_protocol}://#{admin_address}:#{api_bind_port}"


    let(:region) { Noop.hiera('region', 'RegionOne') }
    let(:tenant) { Noop.hiera_structure('murano/tenant', 'services') }

    let(:murano_password) { Noop.hiera_structure('murano/user_password') }

    ##########################################################################

    it 'should have explicit ordering between LB classes and particular actions' do
      expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-public]",
                                                      "Class[murano::keystone::auth]")
      expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-admin]",
                                                      "Class[murano::keystone::auth]")
    end

    it 'should declare murano::keystone::auth class correctly' do
      should contain_class('murano::keystone::auth').with(
                 'password'     => murano_password,
                 'region'       => region,
                 'tenant'       => tenant,
                 'public_url'   => public_url,
                 'internal_url' => internal_url,
                 'admin_url'    => admin_url
             )
    end

  end
  test_ubuntu_and_centos manifest
end
