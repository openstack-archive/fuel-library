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
manifest = 'openstack-haproxy/openstack-haproxy-radosgw.pp'

describe manifest do
  shared_examples 'catalog' do

    images_ceph = Noop.hiera_structure 'storage/images_ceph'
    objects_ceph = Noop.hiera_structure 'storage/objects_ceph'

    if images_ceph and objects_ceph and !Noop.hiera('external_lb', false)

      rgw_nodes = Noop.hiera_hash('ceph_rgw_nodes')

      let(:rgw_address_map) do
        Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', rgw_nodes, 'heat/api'
      end

      let(:ipaddresses) do
        rgw_address_map.values
      end

      let(:server_names) do
        rgw_address_map.keys
      end

      ironic_enabled = Noop.hiera_structure 'ironic/enabled'

      if ironic_enabled

        baremetal_virtual_ip = Noop.hiera_structure 'network_metadata/vips/baremetal/ipaddr'

        it 'should declare ::openstack::ha::radosgw class with baremetal_virtual_ip' do
          should contain_class('openstack::ha::radosgw').with(
            'baremetal_virtual_ip' => baremetal_virtual_ip,
          )
        end

        it "should properly configure radosgw haproxy based on ssl" do
          public_ssl_radosgw = Noop.hiera_structure('public_ssl/services', false)
          should contain_openstack__ha__haproxy_service('object-storage').with(
            'order'                  => '130',
            'ipaddresses'            => ipaddresses,
            'server_names'           => server_names,
            'listen_port'            => 8080,
            'balancermember_port'    => 6780,
            'public'                 => true,
            'public_ssl'             => public_ssl_radosgw,
            'require_service'        => 'radosgw-api',
            'haproxy_config_options' => {
              'option'       => ['httplog', 'httpchk GET /'],
              'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
            },
          )
        end

        it 'should declare openstack::ha::haproxy_service with name radosgw-baremetal' do
          should contain_openstack__ha__haproxy_service('object-storage-baremetal').with(
            'order'                  => '135',
            'ipaddresses'            => ipaddresses,
            'server_names'           => server_names,
            'listen_port'            => 8080,
            'balancermember_port'    => 6780,
            'public_virtual_ip'      => false,
            'internal_virtual_ip'    => baremetal_virtual_ip,
            'haproxy_config_options' => {
              'option'       => ['httplog', 'httpchk GET /'],
              'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
            },
          )
        end

      end

    end

  end # end of shared_examples
  test_ubuntu_and_centos manifest
end
