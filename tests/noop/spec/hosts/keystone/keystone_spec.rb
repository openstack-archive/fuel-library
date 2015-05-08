require 'spec_helper'
require 'shared-examples'
manifest = 'keystone/keystone.pp'

describe manifest do
  shared_examples 'catalog' do

    # TODO All this stuff should be moved to shared examples controller* tests.

    nodes = Noop.hiera 'nodes'
    internal_address = Noop.node_hash['internal_address']
    primary_controller_nodes = Noop::Utils.filter_nodes(nodes,'role','primary-controller')
    controllers = primary_controller_nodes + Noop::Utils.filter_nodes(nodes,'role','controller')
    controller_internal_addresses = Noop::Utils.nodes_to_hash(controllers,'name','internal_address')
    controller_nodes = Noop::Utils.ipsort(controller_internal_addresses.values)
    memcached_servers = controller_nodes.map{ |n| n = n + ':11211' }.join(',')
    admin_token = Noop.hiera_structure 'keystone/admin_token'

    # Keystone
    it 'should declare keystone class with admin_token' do
      should contain_class('keystone').with(
        'admin_token' => admin_token,
      )
    end
    it 'should configure memcache_pool keystone cache backend' do
      should contain_keystone_config('token/caching').with(:value => 'false')
      should contain_keystone_config('cache/enabled').with(:value => 'true')
      should contain_keystone_config('cache/backend').with(:value => 'keystone.cache.memcache_pool')
      should contain_keystone_config('cache/memcache_servers').with(:value => memcached_servers)
      should contain_keystone_config('cache/memcache_dead_retry').with(:value => '30')
      should contain_keystone_config('cache/memcache_socket_timeout').with(:value => '1')
      should contain_keystone_config('cache/memcache_pool_maxsize').with(:value => '1000')
      should contain_keystone_config('cache/memcache_pool_unused_timeout').with(:value => '60')
    end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

