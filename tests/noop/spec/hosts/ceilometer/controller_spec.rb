require 'spec_helper'
require 'shared-examples'
manifest = 'ceilometer/controller.pp'

describe manifest do
  shared_examples 'puppet catalogue' do

    # TODO All this stuff should be moved to shared examples controller* tests.

    settings = Noop.fuel_settings
    internal_address = Noop.node_hash['internal_address']
    rabbit_user = settings['rabbit']['user'] || 'nova'
    use_neutron = settings['quantum'].to_s
    rabbit_ha_queues = 'true'

    # Ceilometer
    if settings['ceilometer']['enabled']
      it 'should declare openstack::ceilometer class with correct parameters' do
        should contain_class('openstack::ceilometer').with(
          'amqp_user'        => rabbit_user,
          'amqp_password'    => settings['rabbit']['password'],
          'rabbit_ha_queues' => rabbit_ha_queues,
          'on_controller'    => 'true',
        )
      end
    end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

