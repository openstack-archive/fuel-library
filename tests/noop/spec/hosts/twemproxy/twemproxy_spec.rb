require 'spec_helper'
require 'shared-examples'
manifest = 'twemproxy/twemproxy.pp'


describe manifest do

  shared_examples 'catalog' do

    network_metadata     = Noop.hiera 'network_metadata'
    memcache_roles       = Noop.hiera 'memcache_roles'
    memcache_addresses   = Noop.hiera 'memcached_addresses', false
    memcache_server_port = '11211'

    let(:memcache_nodes) do
      Noop.puppet_function 'get_nodes_hash_by_roles', network_metadata, memcache_roles
    end

    let(:memcache_address_map) do
      Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', memcache_nodes, 'mgmt/memcache'
    end

    let (:memcache_servers) do
      if not memcache_addresses
        memcache_address_map.values.map! { |server| "#{server}:#{memcache_server_port}:1" }
      else
        memcache_addresses.map! { |server| "#{server}:#{memcache_server_port}:1" }
      end
    end

    it 'should declare twemproxy class with right memcache servers array' do
      should contain_class('twemproxy').with(
        'clients_array' => memcache_servers,
      )
    end
  end

  test_ubuntu_and_centos manifest
end

