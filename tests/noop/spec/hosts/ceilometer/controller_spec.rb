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
          'use_stderr'       => 'false',
        )
      end
      it 'should configure OS ENDPOINT TYPE for ceilometer' do
        should contain_ceilometer_config('service_credentials/os_endpoint_type').with(:value => 'internalURL')
      end
    end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

