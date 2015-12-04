require 'spec_helper'
require 'shared-examples'
manifest = 'ceilometer/controller.pp'

describe manifest do
  shared_examples 'catalog' do

    # TODO All this stuff should be moved to shared examples controller* tests.

    rabbit_user = Noop.hiera_structure 'rabbit/user', 'nova'
    rabbit_password = Noop.hiera_structure 'rabbit/password'
    ceilometer_hash = Noop.hiera_structure 'ceilometer'
    rabbit_ha_queues = 'true'
    default_log_levels_hash = Noop.hiera_structure 'default_log_levels'
    default_log_levels = Noop.puppet_function 'join_keys_to_values',default_log_levels_hash,'='

    # Ceilometer
    if ceilometer_hash['enabled']
      it 'should declare openstack::ceilometer class with correct parameters' do
        should contain_class('openstack::ceilometer').with(
          'amqp_user'        => rabbit_user,
          'amqp_password'    => rabbit_password,
          'rabbit_ha_queues' => rabbit_ha_queues,
          'on_controller'    => 'true',
          'use_stderr'       => 'false',
        )
      end
      it 'should configure OS ENDPOINT TYPE for ceilometer' do
        should contain_ceilometer_config('service_credentials/os_endpoint_type').with(:value => 'internalURL')
      end
      alarm_ttl = ceilometer_hash['alarm_history_time_to_live'] ? (ceilometer_hash['alarm_history_time_to_live']) : ('604800')
      event_ttl = ceilometer_hash['event_time_to_live'] ? (ceilometer_hash['event_time_to_live']) : ('604800')
      metering_ttl = ceilometer_hash['metering_time_to_live'] ? (ceilometer_hash['metering_time_to_live']) : ('604800')
      http_timeout = ceilometer_hash['http_timeout'] ? (ceilometer_hash['http_timeout']) : ('600')
      it 'should configure time to live for alarm history, events and meters' do
        should contain_ceilometer_config('database/alarm_history_time_to_live').with(:value => alarm_ttl)
        should contain_ceilometer_config('database/event_time_to_live').with(:value => event_ttl)
        should contain_ceilometer_config('database/metering_time_to_live').with(:value => metering_ttl)
      end
      it 'should configure timeout for HTTP requests' do
        should contain_ceilometer_config('DEFAULT/http_timeout').with(:value => http_timeout)
      end

      it 'should configure default log levels' do
        should contain_ceilometer_config('DEFAULT/default_log_levels').with_value(default_log_levels.sort.join(','))
      end
    end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

