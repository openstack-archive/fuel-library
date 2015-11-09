require 'spec_helper'
require 'shared-examples'
manifest = 'keystone/keystone.pp'

describe manifest do
  shared_examples 'catalog' do

    # TODO All this stuff should be moved to shared examples controller* tests.

    network_metadata     = Noop.hiera 'network_metadata'
    memcache_roles       = Noop.hiera 'memcache_roles'
    memcache_server_port = Noop.hiera 'memcache_server_port', '11211'

    let(:memcache_nodes) do
      Noop.puppet_function 'get_nodes_hash_by_roles', network_metadata, memcache_roles
    end

    let(:memcache_address_map) do
      Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', memcache_nodes, 'mgmt/memcache'
    end

    let (:memcache_servers) do
      memcache_address_map.values.map { |server| "#{server}:#{memcache_server_port}" }.join(",")
    end

    let(:configuration_override) do
      Noop.hiera_structure 'configuration'
    end

    let(:keystone_config_override) do
      configuration_override.fetch('keystone_config', {})
    end

    nodes = Noop.hiera 'nodes'
    internal_address = Noop.node_hash['internal_address']
    primary_controller_nodes = Noop.puppet_function('filter_nodes', nodes, 'role', 'primary-controller')
    controllers = primary_controller_nodes + Noop.puppet_function('filter_nodes', nodes, 'role', 'controller')
    controller_internal_addresses = Noop.puppet_function('nodes_to_hash', controllers, 'name', 'internal_address')
    controller_nodes = Noop.puppet_function('ipsort', controller_internal_addresses.values)
    admin_token = Noop.hiera_structure 'keystone/admin_token'
    public_vip = Noop.hiera('public_vip')
    management_vip= Noop.hiera('management_vip')
    public_ssl_hash = Noop.hiera('public_ssl')
    ssl_hostname = public_ssl_hash['hostname']
    public_url = "https://#{ssl_hostname}:5000"
    admin_url = "http://#{management_vip}:35357"
    internal_url = "http://#{management_vip}:5000"
    revoke_driver = 'keystone.contrib.revoke.backends.sql.Revoke'
    database_idle_timeout = '3600'
    ceilometer_hash = Noop.hiera_structure 'ceilometer'

    it 'should declare keystone class with admin_token' do
      should contain_class('keystone').with(
        'admin_token' => admin_token,
      )
    end

    it 'should declare openstack::keystone class with public_url,admin_url,internal_url' do
        should contain_class('openstack::keystone').with('public_url' => public_url)
        should contain_class('openstack::keystone').with('admin_url' => admin_url)
        should contain_class('openstack::keystone').with('internal_url' => internal_url)
    end


    it 'should configure keystone with paramters' do
      should contain_keystone_config('token/caching').with(:value => 'false')
      should contain_keystone_config('cache/enabled').with(:value => 'true')
      should contain_keystone_config('cache/backend').with(:value => 'keystone.cache.memcache_pool')
      should contain_keystone_config('memcache/servers').with(:value => memcache_servers)
      should contain_keystone_config('cache/memcache_dead_retry').with(:value => '60')
      should contain_keystone_config('cache/memcache_socket_timeout').with(:value => '1')
      should contain_keystone_config('cache/memcache_pool_maxsize').with(:value => '1000')
      should contain_keystone_config('cache/memcache_pool_unused_timeout').with(:value => '60')
      should contain_keystone_config('memcache/dead_retry').with(:value => '60')
      should contain_keystone_config('memcache/socket_timeout').with(:value => '1')
      should contain_keystone_config('DEFAULT/public_endpoint').with(:value => public_url)
    end

    it 'should configure revoke_driver for keystone' do
      should contain_keystone_config('revoke/driver').with(:value => revoke_driver)
    end

    it 'should configure database_idle_timeout for keystone' do
      should contain_keystone_config('database/idle_timeout').with(:value => database_idle_timeout)
    end

    it 'should contain token_caching parameter for keystone set to false' do
      should contain_class('keystone').with('token_caching' => 'false')
      should contain_keystone_config('token/caching').with(:value => 'false')
    end

     it 'should declare keystone::wsgi::apache class with 4 processess and 3 threads on 4 CPU system' do
       should contain_class('keystone::wsgi::apache').with(
         'threads'               => '3',
         'workers'               => '4',
         'vhost_custom_fragment' => 'LimitRequestFieldSize 81900',
       )
     end

     it 'should declare keystone::wsgi::apache class with 6 processes and 3 threads on 48 CPU system' do
       facts[:processorcount] = 48
       should contain_class('keystone::wsgi::apache').with(
         'threads' => '3',
         'workers' => '6',
       )
     end

     it 'should declare keystone::wsgi::apache class with 1 process and 3 threads on 1 CPU system' do
       facts[:processorcount] = 1
       should contain_class('keystone::wsgi::apache').with(
         'threads' => '3',
         'workers' => '1',
       )
     end

     it 'should setup keystone_wsgi_admin file properly' do
       case facts[:operatingsystem]
       when 'CentOS'
         should contain_file('keystone_wsgi_admin').with(
           'ensure'  => 'link',
           'path'    => "/var/www/cgi-bin/keystone/admin",
           'target'  => '/usr/share/keystone/keystone.wsgi',
           'owner'   => 'keystone',
           'group'   => 'keystone',
           'mode'    => '0644',
         )
       when 'Ubuntu'
         should contain_file('keystone_wsgi_admin').with(
           'ensure'  => 'file',
           'path'    => "/usr/lib/cgi-bin/keystone/admin",
           'source'  => '/usr/share/keystone/wsgi.py',
           'owner'   => 'keystone',
           'group'   => 'keystone',
           'mode'    => '0644',
         )
       end
     end

     it 'should not run keystone service' do
       should contain_service('keystone').with(
         'ensure' => 'stopped',
       )
     end
     it 'should configure apache to listen 5000 keystone port' do
       should contain_apache__listen('5000')
     end
     it 'should configure apache to listen 35357 keystone port' do
       should contain_apache__listen('35357')
     end

     it 'should disable use_stderr for keystone' do
       should contain_keystone_config('DEFAULT/use_stderr').with(:value => 'false')
     end

     it 'should create/update params with override_resources' do
       is_expected.to contain_override_resources('keystone_config').with(:data => keystone_config_override)
     end

    it 'should use "override_resources" to update the catalog' do
      ral_catalog = Noop.create_ral_catalog self
      keystone_config_override.each do |title, params|
        params['value'] = 'True' if params['value'].is_a? TrueClass
        expect(ral_catalog).to contain_keystone_config(title).with(params)
      end
    end

     if ceilometer_hash and ceilometer_hash['enabled']
       it 'should configure notification driver' do
         should contain_keystone_config('DEFAULT/notification_driver').with(:value => 'messagingv2')
       end
     end

     it {
       should contain_service('httpd').with(
            'hasrestart' => true,
            'restart'    => 'sleep 30 && apachectl graceful || apachectl restart'
       )
     }

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

