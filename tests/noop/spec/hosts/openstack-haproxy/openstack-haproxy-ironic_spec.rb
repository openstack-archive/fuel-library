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
manifest = 'openstack-haproxy/openstack-haproxy-ironic.pp'

ironic_enabled = Noop.hiera_structure 'ironic/enabled'
if ironic_enabled
  describe manifest do
    shared_examples 'catalog' do

      ironic_api_nodes = Noop.hiera_hash('ironic_api_nodes')

      let(:ironic_address_map) do
        Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', ironic_api_nodes, 'ironic/api'
      end

      let(:ipaddresses) do
        ironic_address_map.values
      end

      let(:server_names) do
        ironic_address_map.keys
      end

      use_ironic = Noop.hiera_structure('ironic/enabled', true)
      baremetal_virtual_ip = Noop.hiera_structure 'network_metadata/vips/baremetal/ipaddr'
      public_ssl_ironic = Noop.hiera_structure('public_ssl/services', false)

      if use_ironic and !Noop.hiera('external_lb', false)
        it "should properly configure ironic haproxy based on ssl" do
          should contain_openstack__ha__haproxy_service('ironic').with(
            'order'                  => '180',
            'ipaddresses'            => ipaddresses,
            'server_names'           => server_names,
            'listen_port'            => 6385,
            'public'                 => true,
            'public_ssl'             => public_ssl_ironic,
            'haproxy_config_options' => {
              'option'       => ['httpchk GET /', 'httplog', 'httpclose'],
              'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
            },

          )
        end
        it "should properly configure ironic haproxy on baremetal vip" do
          should contain_openstack__ha__haproxy_service('ironic-baremetal').with(
            'order'                  => '185',
            'ipaddresses'            => ipaddresses,
            'server_names'           => server_names,
            'listen_port'            => 6385,
            'public_virtual_ip'      => false,
            'internal_virtual_ip'    => baremetal_virtual_ip,
            'haproxy_config_options' => {
              'option'       => ['httpchk GET /', 'httplog', 'httpclose'],
              'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
            },

          )
        end
      end

      it 'should declare openstack::ha::ironic class with baremetal_virtual_ip' do
        should contain_class('openstack::ha::ironic').with(
          'baremetal_virtual_ip' => baremetal_virtual_ip,
        )
      end
    end # end of shared_examples
    test_ubuntu_and_centos manifest
  end
end # ironic
