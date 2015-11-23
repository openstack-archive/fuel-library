require 'spec_helper'
require 'shared-examples'
manifest = 'twemproxy/twemproxy.pp'

describe manifest do
  shared_examples 'catalog' do
    network_metadata     = Noop.hiera 'network_metadata'
    memcache_roles       = Noop.hiera 'memcache_roles'
    memcache_nodes       = Noop.puppet_function 'get_nodes_hash_by_roles', network_metadata, memcache_roles
    memcache_address_map = Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', memcache_nodes, 'mgmt/memcache'
    memcache_server_port = Noop.hiera 'memcache_server_port', '11211'
    memcache_servers     = memcache_address_map.values.map { |server| "#{server}:#{memcache_server_port}:1" }.join(",")

    it 'contain twemproxy class with correct memcached servers' do
      should contain_class('twemproxy').with(
        'clients_array' => memcache_servers,
      )
    end

  end

  test_ubuntu_and_centos manifest
end
