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
manifest = 'ceph/radosgw_keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    radosgw_enabled = Noop.hiera_structure('storage/objects_ceph', false)
    if radosgw_enabled
      region            = Noop.hiera('region', 'RegionOne')
      ssl_hash          = Noop.hiera_structure('use_ssl', {})
      public_ssl_hash   = Noop.hiera_structure('public_ssl', {})

      let(:internal_protocol) {
        Noop.puppet_function 'get_ssl_property',ssl_hash,{},'radosgw',
          'internal','protocol','http'
      }

      let(:internal_address) {
        Noop.puppet_function 'get_ssl_property',ssl_hash,{},'radosgw',
          'internal','hostname', [Noop.hiera('management_vip')]
      }

      let(:admin_protocol) {
        Noop.puppet_function 'get_ssl_property',ssl_hash,{},'radosgw',
          'admin','protocol','http'
      }

      let(:admin_address) {
        Noop.puppet_function 'get_ssl_property',ssl_hash,{},'radosgw','admin',
          'hostname', [Noop.hiera('management_vip')]
      }

      let(:public_protocol) {
        Noop.puppet_function 'get_ssl_property',ssl_hash,public_ssl_hash,'radosgw',
          'public','protocol','http'
      }

      let(:public_address) {
        Noop.puppet_function 'get_ssl_property',ssl_hash,public_ssl_hash,'radosgw','public',
          'hostname', [Noop.hiera('public_vip')]
      }

      it 'should configure radosgw keystone endpoint' do
        should contain_keystone__resource__service_identity('radosgw').with(
          'configure_user'      => false,
          'configure_user_role' => false,
          'service_type'        => 'object-store',
          'service_description' => 'Openstack Object-Store Service',
          'service_name'        => 'swift',
          'region'              => region,
          'public_url'          => "#{public_protocol}://#{public_address}:8080/swift/v1",
          'admin_url'           => "#{internal_protocol}://#{internal_address}:8080/swift/v1",
          'internal_url'        => "#{admin_protocol}://#{admin_address}:8080/swift/v1",
        )
      end

      it 'should have explicit ordering between LB classes and particular actions' do
        expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-public]",
                                                      "Keystone::Resource::Service_identity[radosgw]")
        expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-admin]",
                                                      "Keystone::Resource::Service_identity[radosgw]")
      end
    end
  end
  test_ubuntu_and_centos manifest
end
