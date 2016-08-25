# ROLE: compute-vmware
# ROLE: compute

require 'spec_helper'
require 'shared-examples'
manifest = 'ceilometer/compute.pp'

describe manifest do
  shared_examples 'catalog' do
    ceilometer_hash = Noop.hiera_structure 'ceilometer'
    default_log_levels_hash = Noop.hiera_structure 'default_log_levels'
    default_log_levels = Noop.puppet_function 'join_keys_to_values',default_log_levels_hash,'='

    region                 = Noop.hiera 'region', 'RegionOne'
    ceilometer_region      = Noop.puppet_function 'pick',ceilometer_hash['region'], region
    management_vip         = Noop.hiera 'management_vip'
    service_endpoint       = Noop.hiera 'service_endpoint', management_vip
    ssl_hash               = Noop.hiera_structure('use_ssl', {})
    internal_auth_protocol = Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','protocol','http'
    internal_auth_endpoint = Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','hostname',[service_endpoint]
    rabbit_hash            = Noop.hiera_structure 'rabbit', {}

    admin_auth_protocol    = Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin','protocol','http'
    admin_auth_endpoint    = Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin','hostname',[service_endpoint]

    keystone_identity_uri  = "#{admin_auth_protocol}://#{admin_auth_endpoint}:35357/"
    keystone_auth_uri      = "#{internal_auth_protocol}://#{internal_auth_endpoint}:5000/"
    kombu_compression      = Noop.hiera 'kombu_compression', ''

    rabbit_heartbeat_timeout_threshold = Noop.puppet_function 'pick', ceilometer_hash['rabbit_heartbeat_timeout_threshold'], rabbit_hash['heartbeat_timeout_treshold'], 60
    rabbit_heartbeat_rate = Noop.puppet_function 'pick', ceilometer_hash['rabbit_heartbeat_rate'], rabbit_hash['heartbeat_rate'], 2

    if ceilometer_hash['enabled']
      it 'should configure RabbitMQ Heartbeat parameters' do
        should contain_ceilometer_config('oslo_messaging_rabbit/heartbeat_timeout_threshold').with_value(rabbit_heartbeat_timeout_threshold)
        should contain_ceilometer_config('oslo_messaging_rabbit/heartbeat_rate').with_value(rabbit_heartbeat_rate)
      end

      it 'should configure interface (ex. OS ENDPOINT TYPE) for ceilometer' do
        should contain_ceilometer_config('service_credentials/interface').with(:value => 'internalURL')
      end
      event_ttl = ceilometer_hash['event_time_to_live'] ? (ceilometer_hash['event_time_to_live']) : ('604800')
      metering_ttl = ceilometer_hash['metering_time_to_live'] ? (ceilometer_hash['metering_time_to_live']) : ('604800')
      http_timeout = ceilometer_hash['http_timeout'] ? (ceilometer_hash['http_timeout']) : ('600')
      it 'should configure time to live for events and meters' do
        should contain_ceilometer_config('database/event_time_to_live').with(:value => event_ttl)
        should contain_ceilometer_config('database/metering_time_to_live').with(:value => metering_ttl)
      end
      it 'should configure timeout for HTTP requests' do
        should contain_ceilometer_config('DEFAULT/http_timeout').with(:value => http_timeout)
      end
      it 'should disable use_stderr option' do
        should contain_ceilometer_config('DEFAULT/use_stderr').with(:value => 'false')
      end

      it 'should configure default_log_levels' do
        should contain_ceilometer_config('DEFAULT/default_log_levels').with_value(default_log_levels.sort.join(','))
      end

      it 'should configure auth_url' do
        should contain_ceilometer_config('service_credentials/auth_url').with(:value => keystone_auth_uri)
      end

      it 'contains class ceilometer::agent::polling' do
        should contain_class('ceilometer::agent::polling').with(
          'central_namespace' => 'false',
          'ipmi_namespace'    => 'false',
        )
      end

      auth_user = Noop.puppet_function, 'pick', ceilometer_hash['user'], 'ceilometer'
      auth_tenant_name = Noop.puppet_function, 'pick', ceilometer_hash['auth_tenant_name'], 'ceilometer'

      it 'configured ceilometer::agent::auth' do
        should contain_class('ceilometer::agent::auth').with(
          'auth_url'         => keystone_auth_uri,
          'auth_password'    => ceilometer_hash['user_password'],
          'auth_region'      => ceilometer_region,
          'auth_tenant_name' => auth_tenant_name,
          'auth_user'        => auth_user,
        )
      end

      it 'should properly configure rabbit queue' do
        should contain_ceilometer_config('DEFAULT/rpc_backend').with(:value => 'rabbit')
        should contain_ceilometer_config('oslo_messaging_rabbit/rabbit_virtual_host').with(:value => '/')
        should contain_ceilometer_config('oslo_messaging_rabbit/rabbit_use_ssl').with(:value => 'false')
      end

      it 'should configure kombu compression' do
        kombu_compression = Noop.hiera 'kombu_compression', facts[:os_service_default]
        should contain_ceilometer_config('oslo_messaging_rabbit/kombu_compression').with(:value => kombu_compression)
      end
    end
  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

