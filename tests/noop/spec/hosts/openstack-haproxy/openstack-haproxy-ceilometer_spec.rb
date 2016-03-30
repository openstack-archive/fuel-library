# HIERA: neut_vlan.ceph.ceil-primary-controller.overridden_ssl
# HIERA: neut_vlan.ceph.controller-ephemeral-ceph
# HIERA: neut_vlan.ironic.controller
# HIERA: neut_vlan_l3ha.ceph.ceil-controller
# HIERA: neut_vlan_l3ha.ceph.ceil-primary-controller
# HIERA: neut_vxlan_dvr.murano.sahara-controller
# HIERA: neut_vxlan_dvr.murano.sahara-primary-controller
# HIERA: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl

require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-haproxy/openstack-haproxy-ceilometer.pp'

describe manifest do
  shared_examples 'catalog' do

    ceilometer_nodes = Noop.hiera_hash('ceilometer_nodes')

    let(:ceilometer_address_map) do
      Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', ceilometer_nodes, 'heat/api'
    end

    let(:ipaddresses) do
      ceilometer_address_map.values
    end

    let(:server_names) do
      ceilometer_address_map.keys
    end

    use_ceilometer = Noop.hiera_structure('ceilometer/enabled', false)

    if use_ceilometer and !Noop.hiera('external_lb', false)
      it "should properly configure ceilometer haproxy based on ssl" do
        public_ssl_ceilometer = Noop.hiera_structure('public_ssl/services', false)
        should contain_openstack__ha__haproxy_service('ceilometer').with(
          'order'                  => '140',
          'ipaddresses'            => ipaddresses,
          'server_names'           => server_names,
          'listen_port'            => 8777,
          'public'                 => true,
          'public_ssl'             => public_ssl_ceilometer,
          'require_service'        => 'ceilometer-api',
          'haproxy_config_options' => {
            'option'       => ['httplog', 'forceclose'],
            'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
          },
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end
