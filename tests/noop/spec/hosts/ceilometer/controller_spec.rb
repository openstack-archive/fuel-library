require 'spec_helper'
require 'shared-examples'
manifest = 'ceilometer/controller.pp'

describe manifest do
  shared_examples 'catalog' do

    # TODO All this stuff should be moved to shared examples controller* tests.

    rabbit_user = Noop.hiera_structure 'rabbit/user', 'nova'
    rabbit_password = Noop.hiera_structure 'rabbit/password'
    enabled = Noop.hiera_structure 'ceilometer/enabled'
    rabbit_ha_queues = 'true'

    # Ceilometer
    if enabled
      it 'should declare openstack::ceilometer class with correct parameters' do
        should contain_class('openstack::ceilometer').with(
          'amqp_user'        => rabbit_user,
          'amqp_password'    => rabbit_password,
          'rabbit_ha_queues' => rabbit_ha_queues,
          'on_controller'    => 'true',
        )
      end
      it 'should configure OS ENDPOINT TYPE for ceilometer' do
        should contain_ceilometer_config('service_credentials/os_endpoint_type').with(:value => 'internalURL')
      end
      it 'should configure time to live for events and meters' do
        should contain_ceilometer_config('database/event_time_to_live').with(:value => '604800')
        should contain_ceilometer_config('database/metering_time_to_live').with(:value => '604800')
      end
      it 'should configure timeout for HTTP requests' do
        should contain_ceilometer_config('DEFAULT/http_timeout').with(:value => '600')
      end
    end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

