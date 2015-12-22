require 'spec_helper'
require 'shared-examples'
manifest = 'roles/ironic-compute.pp'

describe manifest do
  shared_examples 'catalog' do
    ironic_user_password = Noop.hiera_structure 'ironic/user_password'
    ironic_enabled = Noop.hiera_structure 'ironic/enabled'

    let(:max_pool_size) { Noop.hiera('max_pool_size') }
    let(:max_overflow) { Noop.hiera('max_overflow') }
    let(:max_retries) { Noop.hiera('max_retries') }
    let(:idle_timeout) { Noop.hiera('idle_timeout') }

    network_metadata     = Noop.hiera 'network_metadata'
    memcache_roles       = Noop.hiera 'memcache_roles'
    memcache_addresses   = Noop.hiera 'memcached_addresses', false
    memcache_server_port = Noop.hiera 'memcache_server_port', '11211'

    let(:memcache_nodes) do
      Noop.puppet_function 'get_nodes_hash_by_roles', network_metadata, memcache_roles
    end

    let(:memcache_address_map) do
      Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', memcache_nodes, 'mgmt/memcache'
    end

    let (:memcache_servers) do
      if not memcache_addresses
        memcache_address_map.values.map { |server| "#{server}:#{memcache_server_port}" }.join(",")
      else
        memcache_addresses.map { |server| "#{server}:#{memcache_server_port}" }.join(",")
      end
    end

    if ironic_enabled
      it 'nova config should have correct nova_user_password' do
        should contain_nova_config('ironic/admin_password').with(:value => ironic_user_password)
        should contain_nova_config('DEFAULT/compute_driver').with(:value => 'ironic.IronicDriver')
      end

      it 'nova config should have reserved_host_memory_mb set to 0' do
        should contain_nova_config('DEFAULT/reserved_host_memory_mb').with(:value => '0')
      end

      it 'nova config should contain right memcached servers list' do
        should contain_nova_config('DEFAULT/memcached_servers').with(
          'value' => memcache_servers,
        )
      end

      it 'nova-compute.conf should have host set to "ironic-compute"' do
        should contain_file('/etc/nova/nova-compute.conf').with('content'  => "[DEFAULT]\nhost=ironic-compute")
      end


      it 'should configure database connections for nova' do
        should contain_class('nova').with(
          # TODO(aschultz): enable these when nova module is updated with
          # support for these options
          #'database_max_pool_size' => max_pool_size,
          #'database_max_overflow' => max_overflow,
          #'database_max_retries' => max_retries,
          'database_idle_timeout' => idle_timeout)
      end
    end
  end

  test_ubuntu_and_centos manifest
end
