require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-controller/openstack-controller.pp'

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
    admin_token = settings['keystone']['admin_token']

    # Test that catalog compiles and there are no dependency cycles in the graph
    it {
      File.stubs(:exists?).with('/var/lib/astute/ceph/ceph').returns(true)
      File.stubs(:exists?).returns(false)
      should compile
    }

    # Nova config options
    it 'nova config should have report_interval set to 60' do
      should contain_nova_config('DEFAULT/report_interval').with(
        'value' => '60',
      )
    end
    it 'nova config should have service_down_time set to 180' do
      should contain_nova_config('DEFAULT/service_down_time').with(
        'value' => '180',
      )
    end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

