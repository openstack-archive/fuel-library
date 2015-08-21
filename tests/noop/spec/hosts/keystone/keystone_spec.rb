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
      should contain_keystone_config('memcache/dead_retry').with(:value => '30')
    end

    it 'should configure 4 keystone workers for 4 CPUs' do
      should contain_keystone_config('DEFAULT/admin_workers').with(:value => '4')
      should contain_keystone_config('DEFAULT/public_workers').with(:value => '4')
    end

    it 'should configure 16 keystone workers for 40 CPUs' do
      facts[:processorcount] = '40'
      should contain_keystone_config('DEFAULT/admin_workers').with(:value => '16')
      should contain_keystone_config('DEFAULT/public_workers').with(:value => '16')
    end

    # it 'should declare keystone::wsgi::apache class with 4 workers on 4 CPU system' do
    #   should contain_class('keystone::wsgi::apache').with(
    #     'threads' => '1',
    #     'workers' => '4',
    #   )
    # end
    #
    # it 'should declare keystone::wsgi::apache class with 24 workers on 48 CPU system' do
    #   facts[:processorcount] = 48
    #   should contain_class('keystone::wsgi::apache').with(
    #     'threads' => '1',
    #     'workers' => '24',
    #   )
    # end
    #
    # it 'should setup keystone_wsgi_admin file properly' do
    #   case facts[:operatingsystem]
    #   when 'CentOS'
    #     should contain_file('keystone_wsgi_admin').with(
    #       'ensure'  => 'link',
    #       'path'    => "/var/www/cgi-bin/keystone/admin",
    #       'target'  => '/usr/share/keystone/keystone.wsgi',
    #       'owner'   => 'keystone',
    #       'group'   => 'keystone',
    #       'mode'    => '0644',
    #       'require' => "File[/var/www/cgi-bin/keystone]"
    #     )
    #   when 'Ubuntu'
    #     should contain_file('keystone_wsgi_admin').with(
    #       'ensure'  => 'file',
    #       'path'    => "/usr/lib/cgi-bin/keystone/admin",
    #       'source'  => 'puppet:///modules/keystone/httpd/keystone.py',
    #       'owner'   => 'keystone',
    #       'group'   => 'keystone',
    #       'mode'    => '0644',
    #       'require' => "File[/usr/lib/cgi-bin/keystone]"
    #     )
    #   end
    # end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

