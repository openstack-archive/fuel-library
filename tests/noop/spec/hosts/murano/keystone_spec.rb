# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-controller.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-compute.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-cinder.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-mongo.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-controller.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-controller.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-compute.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-ceph-osd.yaml ubuntu
# RUN: neut_vlan.ironic.controller.yaml ubuntu
# RUN: neut_vlan.ironic.conductor.yaml ubuntu
# RUN: neut_vlan.compute.ssl.yaml ubuntu
# RUN: neut_vlan.compute.ssl.overridden.yaml ubuntu
# RUN: neut_vlan.compute.nossl.yaml ubuntu
# RUN: neut_vlan.cinder-block-device.compute.yaml ubuntu
# RUN: neut_vlan.ceph.controller-ephemeral-ceph.yaml ubuntu
# RUN: neut_vlan.ceph.compute-ephemeral-ceph.yaml ubuntu
# RUN: neut_vlan.ceph.ceil-primary-controller.overridden_ssl.yaml ubuntu
# RUN: neut_vlan.ceph.ceil-compute.overridden_ssl.yaml ubuntu
# RUN: neut_gre.generate_vms.yaml ubuntu
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
