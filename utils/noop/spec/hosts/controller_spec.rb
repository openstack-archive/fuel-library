require 'spec_helper'
require File.join File.dirname(__FILE__), '../shared-examples'
manifest = 'controller.pp'

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

    # Test that catalog compiles and there are no dependency cycles in the graph
    it { should compile }

    # Tests for controller roles
    if role == 'primary-controller'
      it_behaves_like 'primary controller with swift'
    end
    it_behaves_like 'controller with keystone', settings['keystone']['admin_token'], memcached_servers
    it_behaves_like 'controller with horizon', settings['nova_quota'], horizon_bind_address
    it_behaves_like 'ha controller with swift'

    if settings['ceilometer']['enabled']
      it_behaves_like 'controller with ceilometer', rabbit_user, settings['rabbit']['password'], use_neutron, rabbit_ha_queues
    end

    if settings['quantum']
      it_behaves_like 'controller with neutron'
    end

    # Tests for plugins
    if settings['sahara']['enabled']
      it_behaves_like 'node with sahara', settings['sahara']['db_password'],  settings['sahara']['user_password'], use_neutron, rabbit_ha_queues
    end
    if settings['murano']['enabled']
      it_behaves_like 'node with murano', rabbit_user, settings['rabbit']['password'], use_neutron
    end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end






