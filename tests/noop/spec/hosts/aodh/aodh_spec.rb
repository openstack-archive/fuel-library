# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'aodh/aodh.pp'

describe manifest do
  shared_examples 'catalog' do
    let(:network_scheme) do
      Noop.hiera_hash 'network_scheme'
    end

    let(:prepare) do
      Noop.puppet_function 'prepare_network_config', network_scheme
    end

    let(:memcache_address) do
      prepare
      Noop.puppet_function 'get_network_role_property', 'mgmt/memcache', 'ipaddr'
    end

    let(:aodh_api_bind_host) do
      Noop.puppet_function 'get_network_role_property', 'aodh/api', 'ipaddr'
    end

    ssl_hash = Noop.hiera_structure 'use_ssl', {}

    management_vip = Noop.hiera 'management_vip'

    internal_auth_protocol = Noop.puppet_function 'get_ssl_property', ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http'
    internal_auth_address = Noop.puppet_function 'get_ssl_property', ssl_hash, {}, 'keystone', 'internal', 'hostname', [management_vip]
    keystone_auth_uri = "#{internal_auth_protocol}://#{internal_auth_address}:5000/v2.0"
    keystone_auth_url = "#{internal_auth_protocol}://#{internal_auth_address}:35357/"

    oslo_policy_file = '/etc/aodh/policy.json'
    notification_store_events = 'true'
    keystone_signing_dir = '/tmp/keystone-signing-aodh'

    aodh_hash = Noop.hiera_structure 'aodh', {}
    tenant = aodh_hash.fetch('tenant', 'services')
    region = aodh_hash.fetch('region', (Noop.hiera 'region', 'RegionOne'))
    user = aodh_hash.fetch('user', 'aodh')
    password = aodh_hash['user_password']

    debug = Noop.hiera 'debug'
    api_pecan_debug = aodh_hash.fetch('debug', debug)

    db_host = Noop.hiera 'database_vip'
    db_name = aodh_hash.fetch('db_name', 'aodh')
    db_user = aodh_hash.fetch('db_user', 'aodh')
    db_password = aodh_hash['db_password']

    rabbit_ha_queues = Noop.hiera 'rabbit_ha_queues'
    rabbit_hash = Noop.hiera_hash 'rabbit', {}
    rabbit_userid = rabbit_hash.fetch('user', 'nova')
    rabbit_password = rabbit_hash['password']

    rabbit_port = Noop.hiera 'amqp_port'
    rabbit_hosts = Noop.hiera 'amqp_hosts'
    kombu_compression = Noop.hiera 'kombu_compression', ''

    ceilometer_hash = Noop.hiera_structure 'ceilometer', {'alarm_history_time_to_live' => '604800'}
    alarm_ttl = Noop.puppet_function 'pick', aodh_hash['alarm_history_time_to_live'], ceilometer_hash['alarm_history_time_to_live']

    it 'should configure "DEFAULT/" section ' do
      should contain_aodh_config('DEFAULT/debug').with(:value => debug)
      should contain_aodh_config('DEFAULT/rpc_backend').with(:value => 'rabbit')
      should contain_aodh_config('oslo_messaging_notifications/topics').with(:value => 'notifications')
    end

    it 'should configure "api/" section ' do
      should contain_aodh_config('api/host').with(:value => "#{aodh_api_bind_host}")
      should contain_aodh_config('api/port').with(:value => '8042')
      should contain_aodh_config('api/pecan_debug').with(:value => api_pecan_debug)
    end

    it 'should configure oslo_policy/policy_file, notification/store_events, api/pecan_debug' do
      # TODO(aschultz): uncomment when this gets merged in upstream aodh module LP#1570109
      #should contain_aodh_config('oslo_policy/policy_file').with(:value => oslo_policy_file)
      should contain_aodh_config('notification/store_events').with(:value => notification_store_events)
    end


    it 'should configure "keystone_authtoken/" section' do
      should contain_aodh_config('keystone_authtoken/memcache_servers').with(:value => "#{memcache_address}:11211")
      should contain_aodh_config('keystone_authtoken/signing_dir').with(:value => keystone_signing_dir)
      should contain_aodh_config('keystone_authtoken/auth_url').with(:value => keystone_auth_url)
      should contain_aodh_config('keystone_authtoken/auth_uri').with(:value => keystone_auth_uri)
      should contain_aodh_config('keystone_authtoken/project_name').with(:value => tenant)
      should contain_aodh_config('keystone_authtoken/username').with(:value => user)
      should contain_aodh_config('keystone_authtoken/password').with(:value => password)
    end

    it 'should configure "service_credentials/" section' do
      should contain_aodh_config('service_credentials/username').with(:value => user)
      should contain_aodh_config('service_credentials/password').with(:value => password)
      should contain_aodh_config('service_credentials/tenant_id').with(:value => tenant)
      should contain_aodh_config('service_credentials/region_name').with(:value => region)
      should contain_aodh_config('service_credentials/endpoint_type').with(:value => 'internalURL')
      should contain_aodh_config('service_credentials/auth_url').with(:value => keystone_auth_uri)
    end

    it 'should configure "oslo_messaging_rabbit/" section' do
      should contain_aodh_config('oslo_messaging_rabbit/rabbit_ha_queues').with(:value => rabbit_ha_queues)
      should contain_aodh_config('oslo_messaging_rabbit/rabbit_virtual_host').with(:value => '/')
      should contain_aodh_config('oslo_messaging_rabbit/rabbit_hosts').with(:value => rabbit_hosts)
      should contain_aodh_config('oslo_messaging_rabbit/rabbit_userid').with(:value => rabbit_userid)
      should contain_aodh_config('oslo_messaging_rabbit/rabbit_password').with(:value => rabbit_password)
    end

    it 'should properly build connection string' do
      if facts[:os_package_type] == 'debian'
        db_params = '?charset=utf8&read_timeout=60'
      else
        db_params = '?charset=utf8'
      end

      should contain_aodh_config('database/connection').with(:value => "mysql://#{db_user}:#{db_password}@#{db_host}/#{db_name}#{db_params}")
    end

    it 'should configure alarm ttl' do
      should contain_aodh_config('database/alarm_history_time_to_live').with(:value => alarm_ttl)
    end

    if ['gzip', 'bz2'].include?(kombu_compression)
      it 'should configure kombu compression' do
        should contain_aodh_config('oslo_messaging_rabbit/kombu_compression').with(:value => kombu_compression)
      end
    end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end
