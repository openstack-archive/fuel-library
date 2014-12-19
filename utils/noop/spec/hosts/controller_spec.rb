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
    admin_token = settings['keystone']['admin_token']
    nova_quota = settings['nova_quota']

    # Test that catalog compiles and there are no dependency cycles in the graph
    it { should compile }

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

    # Swift
    if role == 'primary-controller'
      ['account', 'object', 'container'].each do | ring |
        it "should run pretend_min_part_hours_passed before rabalancing swift #{ring} ring" do
          should contain_exec("hours_passed_#{ring}").with(
            'command' => "swift-ring-builder /etc/swift/#{ring}.builder pretend_min_part_hours_passed",
            'user'    => 'swift',
          )
          should contain_exec("rebalance_#{ring}").with(
            'command' => "swift-ring-builder /etc/swift/#{ring}.builder rebalance",
            'user'    => 'swift',
          ).that_requires("Exec[hours_passed_#{ring}]")
          should contain_exec("create_#{ring}").with(
            'user'    => 'swift',
          )
        end
      end
    end
    it 'should create /etc/swift/backups directory with correct ownership' do
      should contain_file('/etc/swift/backups').with(
        'ensure' => 'directory',
        'owner'  => 'swift',
        'group'  => 'swift',
      )
    end

    # Keystone
    it 'should declare keystone class with admin_token' do
      should contain_class('keystone').with(
        'admin_token' => admin_token,
      )
    end
    it 'should configure memcache_pool keystone cache backend' do
      should contain_keystone_config('token/caching').with(:value => 'false')
      should contain_keystone_config('cache/enabled').with(:value => 'true')
      should contain_keystone_config('cache/backend').with(:value => 'keystone.cache.memcache_pool')
      should contain_keystone_config('cache/memcache_servers').with(:value => memcached_servers)
      should contain_keystone_config('cache/memcache_dead_retry').with(:value => '300')
      should contain_keystone_config('cache/memcache_socket_timeout').with(:value => '3')
      should contain_keystone_config('cache/memcache_pool_maxsize').with(:value => '100')
      should contain_keystone_config('cache/memcache_pool_unused_timeout').with(:value => '60')
    end

    # Horizon
    it 'should declare openstack::horizon class' do
      should contain_class('openstack::horizon').with(
        'nova_quota'   => nova_quota,
        'bind_address' => horizon_bind_address,
      )
    end

    # Ceilometer
    if settings['ceilometer']['enabled']
      it 'should declare openstack::ceilometer class' do
        should contain_class('openstack::ceilometer').with(
          'amqp_user'        => rabbit_user,
          'amqp_password'    => settings['rabbit']['password'],
          'rabbit_ha_queues' => rabbit_ha_queues,
          'on_controller'    => 'true',
        )
      end
      if use_neutron == 'true'
        it 'should configure notification_driver for neutron' do
          should contain_neutron_config('DEFAULT/notification_driver').with(
            'value' => 'messaging',
          )
        end
      end
    end

    # Neutron
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

    # Sahara
    if settings['sahara']['enabled']
      it 'should declare sahara class correctly' do
        should contain_class('sahara').with(
          'sahara_db_password'       => settings['sahara']['db_password'],
          'sahara_keystone_password' => settings['sahara']['user_password'],
          'use_neutron'              => use_neutron,
          'rpc_backend'              => 'rabbit',
          'rabbit_ha_queues'         => rabbit_ha_queues,
        )
      end
    end

    # Murano
    if settings['murano']['enabled']
      it 'should declare murano class correctly and after openstack::heat' do
        should contain_class('murano').with(
          'murano_os_rabbit_userid' => rabbit_user,
          'murano_os_rabbit_passwd' => settings['rabbit']['password'],
          'use_neutron'             => use_neutron,
        ).that_requires('Class[openstack::heat]')
      end
    end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end






