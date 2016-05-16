# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-haproxy/openstack-haproxy-keystone.pp'

describe manifest do
  shared_examples 'catalog' do

    keystone_nodes = Noop.hiera_hash('keystone_nodes')

    let(:keystone_address_map) do
      Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', keystone_nodes, 'heat/api'
    end

    let(:ipaddresses) do
      keystone_address_map.values
    end

    let(:server_names) do
      keystone_address_map.keys
    end

    let(:keystone_hash) { Noop.hiera_hash('keystone') }

    let(:config_options) do
      options = {
        'option' => ['httpchk GET /v3', 'httplog', 'httpclose', 'forwardfor'],
        'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
      }
      session_options = {
        'stick' => ['on src'],
        'stick-table' => ['type ip size 200k expire 2m'],
      }

      if keystone_hash['federation']
        options.merge!(session_options)
      end
      options
    end

    use_keystone = Noop.hiera_structure('keystone/enabled', true)

    if use_keystone and !Noop.hiera('external_lb', false)
      it "should properly configure keystone haproxy based on ssl" do
        public_ssl_keystone = Noop.hiera_structure('public_ssl/services', false)
        should contain_openstack__ha__haproxy_service('keystone-1').with(
          'order'                  => '020',
          'ipaddresses'            => ipaddresses,
          'server_names'           => server_names,
          'listen_port'            => 5000,
          'public'                 => true,
          'public_ssl'             => public_ssl_keystone,
          'haproxy_config_options' => config_options,
        )
      end
      it "should properly configure keystone haproxy admin without public" do
        public_ssl_keystone = Noop.hiera_structure('public_ssl/services', false)
        should contain_openstack__ha__haproxy_service('keystone-2').with(
          'order'                  => '030',
          'ipaddresses'            => ipaddresses,
          'server_names'           => server_names,
          'listen_port'            => 35357,
          'public'                 => false,
          'haproxy_config_options' => config_options,
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end

