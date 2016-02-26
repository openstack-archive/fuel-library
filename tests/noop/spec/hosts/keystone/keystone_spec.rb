require 'spec_helper'
require 'shared-examples'
manifest = 'keystone/keystone.pp'

describe manifest do
  shared_examples 'catalog' do

    # TODO All this stuff should be moved to shared examples controller* tests.
    keystone_hash        = Noop.hiera_structure 'keystone'
    workers_max          = Noop.hiera 'workers_max'
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

    let(:configuration_override) do
      Noop.hiera_structure 'configuration'
    end

    let(:keystone_config_override) do
      configuration_override.fetch('keystone_config', {})
    end

    admin_token = Noop.hiera_structure 'keystone/admin_token'
    public_vip = Noop.hiera('public_vip')
    management_vip= Noop.hiera('management_vip')
    public_ssl_hash = Noop.hiera('public_ssl')

    let(:auth_suffix) { Noop.puppet_function 'pick', keystone_hash['auth_suffix'], '/' }

    let(:ssl_hash) { Noop.hiera_hash 'use_ssl', {} }

    let(:public_auth_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,public_ssl_hash,'keystone','public','protocol','http' }

    let(:public_auth_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,public_ssl_hash,'keystone','public','hostname',[public_vip] }

    let(:internal_auth_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','protocol','http' }

    let(:internal_auth_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','hostname',[Noop.hiera('service_endpoint', ''), management_vip] }

    let(:admin_auth_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin','protocol','http' }

    let(:admin_auth_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin','hostname',[Noop.hiera('service_endpoint', ''), management_vip] }

    let(:public_url) { "#{public_auth_protocol}://#{public_auth_address}:5000" }

    let(:internal_url) { "#{internal_auth_protocol}://#{internal_auth_address}:5000" }

    let(:admin_url) { "#{admin_auth_protocol}://#{admin_auth_address}:35357" }

    revoke_driver = 'keystone.contrib.revoke.backends.sql.Revoke'
    database_idle_timeout = '3600'
    ceilometer_hash = Noop.hiera 'ceilometer_hash', { 'enabled' => false }
    murano_hash = Noop.hiera 'murano_hash', { 'enabled' => false }
    murano_hash['plugins'] = { 'glance_artifacts_plugin' => { 'enabled' => false } }
    murano_plugins = murano_hash['plugins']
    murano_glare_plugin = murano_plugins['glance_artifacts_plugin']
    token_provider = Noop.hiera('token_provider')
    primary_controller = Noop.hiera 'primary_controller'

    database_vip = Noop.hiera('database_vip')
    keystone_db_password = Noop.hiera_structure 'keystone/db_password', 'keystone'
    keystone_db_user = Noop.hiera_structure 'keystone/db_user', 'keystone'
    keystone_db_name = Noop.hiera_structure 'keystone/db_name', 'keystone'

    default_log_levels_hash = Noop.hiera_hash 'default_log_levels'
    default_log_levels = Noop.puppet_function 'join_keys_to_values',default_log_levels_hash,'='

    it 'should configure default_log_levels' do
      should contain_keystone_config('DEFAULT/default_log_levels').with_value(default_log_levels.sort.join(','))
    end

    it 'should configure the database connection string' do
        if facts[:os_package_type] == 'debian'
            extra_params = '?charset=utf8&read_timeout=60'
        else
            extra_params = '?charset=utf8'
        end
        should contain_class('openstack::keystone').with(
          :db_connection => "mysql://#{keystone_db_user}:#{keystone_db_password}@#{database_vip}/#{keystone_db_name}#{extra_params}"

        )
    end

    it 'should declare keystone class with admin_token' do
      should contain_class('keystone').with(
        'admin_token' => admin_token
      )
    end

    it 'should declare openstack::keystone class with public_url,admin_url,internal_url' do
      should contain_class('openstack::keystone').with(
        'public_url'   => public_url,
        'admin_url'    => admin_url,
        'internal_url' => internal_url,
      )
    end

    it 'should declare openstack::auth_file class with proper authentication URL' do
      should contain_class('openstack::auth_file').with(
        'auth_url'        => "#{internal_url}#{auth_suffix}",
      )
    end

    it 'should declare openstack::keystone class with parameter primary controller' do
        should contain_class('openstack::keystone').with('primary_controller' => primary_controller)
    end

    it 'should configure keystone with paramters' do
      should contain_keystone_config('token/caching').with(:value => 'false')
      should contain_keystone_config('cache/enabled').with(:value => 'true')
      should contain_keystone_config('cache/backend').with(:value => 'keystone.cache.memcache_pool')
      should contain_keystone_config('memcache/servers').with(:value => memcache_servers)
      should contain_keystone_config('cache/memcache_servers').with(:value => memcache_servers)
      should contain_keystone_config('cache/memcache_dead_retry').with(:value => '60')
      should contain_keystone_config('cache/memcache_socket_timeout').with(:value => '1')
      should contain_keystone_config('cache/memcache_pool_maxsize').with(:value => '1000')
      should contain_keystone_config('cache/memcache_pool_unused_timeout').with(:value => '60')
      should contain_keystone_config('memcache/dead_retry').with(:value => '60')
      should contain_keystone_config('memcache/socket_timeout').with(:value => '1')
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

      it 'should configure admin and public workers' do
        fallback_workers = [[facts[:processorcount].to_i, 2].max, workers_max.to_i].min
        service_workers = keystone_hash.fetch('workers', fallback_workers)
        should contain_keystone_config('eventlet_server/public_workers').with(:value => service_workers)
        should contain_keystone_config('eventlet_server/admin_workers').with(:value => service_workers)
     end

     it 'should declare keystone::wsgi::apache class with 4 processess and 3 threads on 4 CPU system' do
       should contain_class('keystone::wsgi::apache').with(
         'threads'               => '3',
         'workers'               => '4',
         'vhost_custom_fragment' => 'LimitRequestFieldSize 81900'
       )
     end

     it 'should declare keystone::wsgi::apache class with 6 processes and 3 threads on 48 CPU system' do
       facts[:processorcount] = 48
       should contain_class('keystone::wsgi::apache').with(
         'threads' => '3',
         'workers' => '6'
       )
     end

     it 'should declare keystone::wsgi::apache class with 1 process and 3 threads on 1 CPU system' do
       facts[:processorcount] = 1
       should contain_class('keystone::wsgi::apache').with(
         'threads' => '3',
         'workers' => '1'
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
           'mode'    => '0644'
         )
       when 'Ubuntu'
         should contain_file('keystone_wsgi_admin').with(
           'ensure'  => 'file',
           'path'    => "/usr/lib/cgi-bin/keystone/admin",
           'source'  => '/usr/share/keystone/wsgi.py',
           'owner'   => 'keystone',
           'group'   => 'keystone',
           'mode'    => '0644'
         )
       end
     end

     it 'should not run keystone service' do
       should contain_service('keystone').with(
         'ensure' => 'stopped'
       )
     end

     let (:keystone_api_address) do
       keystone_api_address = Noop.puppet_function('get_network_role_property', 'keystone/api', 'ipaddr')
     end

     it 'should configure apache to listen 5000 keystone port on correct IP address' do
       should contain_apache__listen("#{keystone_api_address}:5000")
     end
     it 'should configure apache to listen 35357 keystone port on correct IP address' do
       should contain_apache__listen("#{keystone_api_address}:35357")
     end

    it 'should contain keystone config with fernet tokens' do
      should contain_keystone_config('token/provider').with(:value => token_provider)
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

    if ceilometer_hash['enabled']
      it 'should configure notification driver' do
        should contain_keystone_config('DEFAULT/notification_driver').with(:value => ceilometer_hash['notification_driver'])
      end
    end

    if murano_glare_plugin['enabled']
      it 'should configure glance_murano_plugin' do
        should contain_class('openstack::auth_file').with(
          :murano_glare_plugin => murano_glare_plugin['enabled']
        )
      end
    end

    if token_provider == 'keystone.token.providers.fernet.Provider'
      it 'should check existence of /etc/keystone/fernet-keys directory' do
        should contain_file('/etc/keystone/fernet-keys').with('source'  => '/var/lib/astute/keystone', 'owner' => 'keystone','group' => 'keystone','mode' => '0600')
      end
    else
      it 'should check non-existence of /etc/keystone/fernet-keys directory' do
        should_not contain_file('/etc/keystone/fernet-keys').with('source'  => '/var/lib/astute/keystone', 'owner' => 'keystone','group' => 'keystone','mode' => '0600')
      end
    end

    it {
      should contain_service('httpd').with(
           'hasrestart' => true,
           'restart'    => 'sleep 30 && apachectl graceful || apachectl restart'
      )
    }

    # FIXME(mattymo): Remove this after LP#1528258 is fixed.
    it 'should have configured DEFAULT/secure_proxy_ssl_header' do
      should contain_keystone_config('DEFAULT/secure_proxy_ssl_header').with(:value => 'HTTP_X_FORWARDED_PROTO')
    end

    it 'should have explicit ordering between LB classes and particular actions' do
      expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-public]",
                                                      "Class[keystone::roles::admin]")
      expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-admin]",
                                                      "Class[keystone::endpoint]")
    end

    it {
      if Noop.hiera('external_lb', false)
        url = internal_url
        provider = 'http'
      else
        url = 'http://' + Noop.hiera('service_endpoint').to_s + ':10000/;csv'
        provider = Puppet::Type.type(:haproxy_backend_status).defaultprovider.name
      end
      should contain_haproxy_backend_status('keystone-public').with(
        :url      => url,
        :provider => provider
      )
    }

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

