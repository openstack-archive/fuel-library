require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/openstack-network-controller.pp'

describe manifest do
  shared_examples 'puppet catalogue' do

    # TODO All this stuff should be moved to shared examples controller* tests.

    use_neutron = Noop.hiera 'use_neutron'
    ceilometer_enabled = Noop.hiera_structure 'ceilometer/enabled'

    # Network
    if use_neutron
      it 'should declare openstack::network with neutron enabled' do
        should contain_class('openstack::network').with(
          'neutron_server' => 'true',
        )
      end
    else
      it 'should declare openstack::network with neutron disabled' do
        should contain_class('openstack::network').with(
          'neutron_server' => 'false',
        )
      end
    end

    # Ceilometer
    if ceilometer_enabled and use_neutron
      it 'should configure notification_driver for neutron' do
        should contain_neutron_config('DEFAULT/notification_driver').with(
          'value' => 'messaging',
        )
      end
    end
  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

