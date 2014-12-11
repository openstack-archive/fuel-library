require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/openstack-network-controller.pp'

describe manifest do
  shared_examples 'puppet catalogue' do

    # TODO All this stuff should be moved to shared examples controller* tests.

    settings = Noop.fuel_settings
    internal_address = Noop.node_hash['internal_address']
    rabbit_user = settings['rabbit']['user'] || 'nova'
    use_neutron = settings['quantum'].to_s
    role = settings['role']
    rabbit_ha_queues = 'true'
    primary_controller_nodes = filter_nodes(settings['nodes'],'role','primary-controller')
    controllers = primary_controller_nodes + filter_nodes(settings['nodes'],'role','controller')
    controller_internal_addresses = nodes_to_hash(controllers,'name','internal_address')
    controller_nodes = ipsort(controller_internal_addresses.values)
    memcached_servers = controller_nodes.map{ |n| n = n + ':11211' }.join(',')
    horizon_bind_address = internal_address
    admin_token = settings['keystone']['admin_token']
    nova_quota = settings['nova_quota']

    # Network
    if settings['quantum']
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
    if settings['ceilometer']['enabled']
      if use_neutron == 'true'
        it 'should configure notification_driver for neutron' do
          should contain_neutron_config('DEFAULT/notification_driver').with(
            'value' => 'messaging',
          )
        end
      end
    end
  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

