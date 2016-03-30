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
manifest = 'openstack-haproxy/openstack-haproxy-nova.pp'

describe manifest do
  shared_examples 'catalog' do

    nova_api_nodes = Noop.hiera_hash('nova_api_nodes')

    let(:nova_api_address_map) do
      Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', nova_api_nodes, 'heat/api'
    end

    let(:ipaddresses) do
      nova_api_address_map.values
    end

    let(:server_names) do
      nova_api_address_map.keys
    end

    use_nova = Noop.hiera_structure('nova/enabled', true)

    if use_nova and !Noop.hiera('external_lb', false)
      it "should properly configure nova haproxy based on ssl" do
        public_ssl_nova = Noop.hiera_structure('public_ssl/services', false)
        should contain_openstack__ha__haproxy_service('nova-api').with(
          'order'                  => '040',
          'ipaddresses'            => ipaddresses,
          'server_names'           => server_names,
          'listen_port'            => 8774,
          'public'                 => true,
          'public_ssl'             => public_ssl_nova,
          'require_service'        => 'nova-api',
          'haproxy_config_options' => {
            'timeout server' => '600s',
            'option'         => ['httpchk', 'httplog', 'httpclose'],
            'http-request'   => 'set-header X-Forwarded-Proto https if { ssl_fc }',
          },
          'balancermember_options' => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
        )
      end
      it "should properly configure nova-metadata-api haproxy" do
        should contain_openstack__ha__haproxy_service('nova-metadata-api').with(
          'order'                  => '050',
          'ipaddresses'            => ipaddresses,
          'server_names'           => server_names,
          'listen_port'            => 8775,
          'haproxy_config_options' => {
            'option'         => ['httpchk', 'httplog', 'httpclose'],
          },
          'balancermember_options' => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
        )
      end
      it "should properly configure nova-novncproxy haproxy based on ssl" do
        public_ssl_nova = Noop.hiera_structure('public_ssl/services', false)
        should contain_openstack__ha__haproxy_service('nova-novncproxy').with(
          'order'                  => '170',
          'ipaddresses'            => ipaddresses,
          'server_names'           => server_names,
          'listen_port'            => 6080,
          'public'                 => true,
          'public_ssl'             => public_ssl_nova,
          'internal'               => false,
          'require_service'        => 'nova-vncproxy',
          'haproxy_config_options' => {
            'http-request'   => 'set-header X-Forwarded-Proto https if { ssl_fc }',
          },
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end

