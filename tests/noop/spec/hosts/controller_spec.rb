require 'spec_helper'
require 'shared-examples'
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

