# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'keystone/keystone.pp'

describe manifest do

  before(:each) do
    Noop.puppet_function_load :is_pkg_installed
    MockFunction.new(:is_pkg_installed) do |function|
      allow(function).to receive(:call).and_return false
    end
  end

  shared_examples 'catalog' do

    # TODO All this stuff should be moved to shared examples controller* tests.
    keystone_hash        = Noop.hiera_structure 'keystone'
    workers_max          = Noop.hiera 'workers_max'

    let(:memcached_servers) { Noop.hiera 'memcached_servers' }

    let(:configuration_override) do
      Noop.hiera_structure 'configuration'
    end

    let(:keystone_config_override) do
      configuration_override.fetch('keystone_config', {})
    end

    let(:admin_token) { Noop.hiera_structure 'keystone/admin_token' }
    let(:admin_password) { Noop.hiera_structure 'access/password' }
    public_vip = Noop.hiera('public_vip')
    management_vip= Noop.hiera('management_vip')
    public_ssl_hash = Noop.hiera_hash('public_ssl')
    let (:region) { Noop.hiera 'region', 'RegionOne' }

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

    database_idle_timeout = '3600'
    ceilometer_hash = Noop.hiera_hash 'ceilometer', { 'enabled' => false }
    murano_hash = Noop.hiera_hash 'murano', { 'enabled' => false }
    murano_hash['plugins'] = { 'glance_artifacts_plugin' => { 'enabled' => false } }
    murano_plugins = murano_hash['plugins']
    murano_glare_plugin = murano_plugins['glance_artifacts_plugin']
    token_provider = Noop.hiera('token_provider')

    database_vip = Noop.hiera('database_vip')
    keystone_db_type = Noop.hiera_structure 'keystone/db_type', 'mysql+pymysql'
    keystone_db_password = Noop.hiera_structure 'keystone/db_password', 'keystone'
    keystone_db_user = Noop.hiera_structure 'keystone/db_user', 'keystone'
    keystone_db_name = Noop.hiera_structure 'keystone/db_name', 'keystone'

    default_log_levels_hash = Noop.hiera_hash 'default_log_levels'
    default_log_levels = Noop.puppet_function 'join_keys_to_values',default_log_levels_hash,'='

    operator_user_hash = Noop.hiera_structure 'operator_user', {}
    service_user_hash = Noop.hiera_structure 'operator_user', {}
    operator_user_name = operator_user_hash['name'] || 'fueladmin'
    operator_user_homedir = operator_user_hash['homedir'] || '/home/fueladmin'
    service_user_name = service_user_hash['name'] || 'fuel'
    service_user_homedir = service_user_hash['homedir'] || '/var/lib/fuel'

    user_admin_role   = Noop.hiera('user_admin_role')
    user_admin_domain = Noop.hiera('user_admin_domain')
    access_hash       = Noop.hiera_hash('access', {})
    admin_user        = access_hash['user']

    primary_keystone = Noop.puppet_function 'has_primary_role', Noop.hiera('keystone_roles') & Noop.hiera('roles')

    rabbit_hash = Noop.hiera_structure 'rabbit', {}

    let(:transport_url) { Noop.hiera 'transport_url', 'rabbit://guest:password@127.0.0.1:5672/' }

    rabbit_heartbeat_timeout_threshold = Noop.puppet_function 'pick', keystone_hash['rabbit_heartbeat_timeout_threshold'], rabbit_hash['heartbeat_timeout_treshold'], 60
    rabbit_heartbeat_rate = Noop.puppet_function 'pick', keystone_hash['rabbit_heartbeat_rate'], rabbit_hash['heartbeat_rate'], 2

    it 'should contain correct transport url' do
      should contain_class('keystone').with(:default_transport_url => transport_url)
      should contain_keystone_config('DEFAULT/transport_url').with_value(transport_url)
    end

    it 'should configure RabbitMQ Heartbeat parameters' do
      should contain_keystone_config('oslo_messaging_rabbit/heartbeat_timeout_threshold').with_value(rabbit_heartbeat_timeout_threshold)
      should contain_keystone_config('oslo_messaging_rabbit/heartbeat_rate').with_value(rabbit_heartbeat_rate)
    end

    it 'should configure default_log_levels' do
      should contain_keystone_config('DEFAULT/default_log_levels').with_value(default_log_levels.sort.join(','))
    end

    it 'should configure the database connection string' do
        if facts[:os_package_type] == 'debian'
            extra_params = '?charset=utf8&read_timeout=60'
        else
            extra_params = '?charset=utf8'
        end
        should contain_class('keystone').with(
          :database_connection => "#{keystone_db_type}://#{keystone_db_user}:#{keystone_db_password}@#{database_vip}/#{keystone_db_name}#{extra_params}"

        )
    end

    it 'should declare keystone class with admin_token and admin_password' do
      should contain_class('keystone').with(
        'admin_token' => admin_token,
        'admin_password' => admin_password
      )
    end

    it 'points to valid admin endpoint' do
      should contain_class('keystone').with(
        'admin_endpoint' => admin_url,
      )
    end

    it 'should enable keystone bootstrap' do
      should contain_class('keystone').with('enable_bootstrap' => true)
    end

    it 'should declare keystone::endpoint class with public_url,admin_url,internal_url' do
      should contain_class('keystone::endpoint').with(
        'public_url'   => public_url,
        'admin_url'    => admin_url,
        'internal_url' => internal_url,
        'region'       => region,
      )
    end

    it 'should create osnailyfacter::credentials_file for root user with proper authentication URL' do
      should contain_osnailyfacter__credentials_file('/root/openrc').with(
        'auth_url'        => "#{internal_url}#{auth_suffix}",
      )
    end

    it 'should create osnailyfacter::credentials_file for operator user with proper authentication URL, owner, group and path' do
      should contain_osnailyfacter__credentials_file("#{operator_user_homedir}/openrc").with(
        'auth_url'        => "#{internal_url}#{auth_suffix}",
        'owner'           => "#{operator_user_name}",
        'group'           => "#{operator_user_name}",
      )
    end

    it 'should create osnailyfacter::credentials_file for service user with proper authentication URL, owner, group and path' do
      should contain_osnailyfacter__credentials_file("#{service_user_homedir}/openrc").with(
        'auth_url'        => "#{internal_url}#{auth_suffix}",
        'owner'           => "#{service_user_name}",
        'group'           => "#{service_user_name}",
      )
    end

    it 'should declare keystone class with parameter primary keystone' do
        should contain_class('keystone').with('sync_db' => primary_keystone)
    end

    it 'should declare keystone class with revoke_by_id set to false' do
      # Set revoke_by_id to false according to LP #1625077
      should contain_class('keystone').with('revoke_by_id' => false)
    end

    it 'should configure keystone with paramters' do
      should contain_keystone_config('token/caching').with(:value => 'false')
      should contain_keystone_config('cache/enabled').with(:value => 'true')
      should contain_keystone_config('cache/backend').with(:value => 'oslo_cache.memcache_pool')
      should contain_keystone_config('memcache/servers').with(:value => memcached_servers.join(','))
      should contain_keystone_config('cache/memcache_servers').with(:value => memcached_servers.join(','))
      should contain_keystone_config('cache/memcache_dead_retry').with(:value => '60')
      should contain_keystone_config('cache/memcache_socket_timeout').with(:value => '1')
      should contain_keystone_config('cache/memcache_pool_maxsize').with(:value => '1000')
      should contain_keystone_config('cache/memcache_pool_unused_timeout').with(:value => '60')
      should contain_keystone_config('memcache/dead_retry').with(:value => '60')
      should contain_keystone_config('memcache/socket_timeout').with(:value => '1')
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

     it 'should declare keystone::wsgi::apache class with 4 processess and 1 threads on 4 CPU system' do
       should contain_class('keystone::wsgi::apache').with(
         'threads'               => '1',
         'workers'               => '4',
         'vhost_custom_fragment' => 'LimitRequestFieldSize 81900'
       )
     end

     it 'should declare keystone::wsgi::apache class with 6 processes and 1 threads on 48 CPU system' do
       facts[:processorcount] = 48
       should contain_class('keystone::wsgi::apache').with(
         'threads' => '1',
         'workers' => '6'
       )
     end

     it 'should declare keystone::wsgi::apache class with 1 process and 1 threads on 1 CPU system' do
       facts[:processorcount] = 1
       should contain_class('keystone::wsgi::apache').with(
         'threads' => '1',
         'workers' => '1'
       )
     end

     it 'should declare keystone::wsgi::apache class with access_log_format set' do
       should contain_class('keystone::wsgi::apache').with(
         'access_log_format' => '%{X-Forwarded-For}i %l %u %{%d/%b/%Y:%T}t.%{msec_frac}t \"%r\" %>s %b %D \"%{Referer}i\" \"%{User-Agent}i\"'
       )
     end

     it 'keystone::wsgi::apache should configure keystone_wsgi_admin and keystone_wsgi_main files' do
       should contain_file('keystone_wsgi_admin')
       should contain_file('keystone_wsgi_main')
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

    it 'should contain oslo_messaging_notifications "driver" option' do
      should contain_keystone_config('oslo_messaging_notifications/driver').with(:value => ceilometer_hash['notification_driver'])
    end

    if murano_glare_plugin['enabled']
      it 'should configure glance_murano_plugin' do
        should contain_osnailyfacter__credentials_file('/root/openrc').with(
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

    if primary_keystone
      it 'should create default _member_ role' do
        should contain_keystone_role('_member_').with('ensure' => 'present')
      end
      it 'should create admin role' do
        should contain_class('keystone::roles::admin').with('admin' => 'admin', 'password' => 'admin',
                             'email' => 'admin@localhost', 'admin_tenant' => 'admin')
      end
      it 'should have explicit ordering between LB classes and particular actions' do
        expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-public]",
                                                      "Class[keystone::roles::admin]")
        expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-public]",
                                                      "Keystone_role[_member_]")
      end

      it 'should add admin role to admin user' do
        should contain_keystone_user_role("#{admin_user}@::#{user_admin_domain}").with('ensure' => 'present','roles' => [user_admin_role])
      end
    end

    it 'should have explicit ordering between LB classes and particular actions' do
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

    it 'should configure kombu compression' do
      kombu_compression = Noop.hiera 'kombu_compression', facts[:os_service_default]
      should contain_keystone_config('oslo_messaging_rabbit/kombu_compression').with(:value => kombu_compression)
    end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

