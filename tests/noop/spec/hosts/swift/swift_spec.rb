require 'spec_helper'
require 'shared-examples'
manifest = 'swift/swift.pp'

describe manifest do
  shared_examples 'catalog' do
    role = Noop.hiera 'role'
    storage_hash = Noop.hiera 'storage'
    swift_hash = Noop.hiera 'swift'
    nodes = Noop.hiera 'nodes'
    primary_controller_nodes = Noop::Utils.filter_nodes(nodes,'role','primary-controller')
    controllers = primary_controller_nodes + Noop::Utils.filter_nodes(nodes,'role','controller')
    controller_internal_addresses = Noop::Utils.nodes_to_hash(controllers,'name','internal_address')
    controller_nodes = Noop::Utils.ipsort(controller_internal_addresses.values)
    ring_part_power = swift_hash.fetch('ring_part_power', 10)
    ring_min_part_hours = Noop.hiera 'swift_ring_min_part_hours', 1
    memcached_servers = controller_nodes.map{ |n| n = n + ':11211' }

    # Swift
    if !(storage_hash['images_ceph'] and storage_hash['objects_ceph']) and !storage_hash['images_vcenter']
      swift_partition = Noop.hiera 'swift_partition'
      unless swift_partition
        swift_partition = '/var/lib/glance/node'
        it 'should allow swift user to write into /var/lib/glance directory' do
          should contain_file('/var/lib/glance').with(
            'ensure' => 'directory',
            'group'  => 'swift',
          ).that_requires('Package[swift]')
        end
      end
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
              'returns' => [0,1],
            ).that_requires("Exec[hours_passed_#{ring}]")
            should contain_exec("create_#{ring}").with(
              'command' => "swift-ring-builder /etc/swift/#{ring}.builder create #{ring_part_power} 3 #{ring_min_part_hours}",
              'user'    => 'swift',
            )
          end
        end
        ['account', 'object', 'container'].each do | ring |
          it "should define swift::ringbuilder::rebalance[#{ring}] before Service[swift-proxy]" do
            should contain_swift__ringbuilder__rebalance(ring).that_comes_before('Service[swift-proxy]')
          end
        end
        ['account', 'object', 'container'].each do | ring |
          ['account', 'object', 'container'].each do | storage |
            it "should define swift::ringbuilder::rebalance[#{ring}] before swift::storage::generic[#{storage}]" do
              should contain_swift__ringbuilder__rebalance(ring).that_comes_before("Swift::Storage::Generic[#{storage}]")
            end
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
      it 'should declare swift::proxy::cache class with correct memcache_servers parameter' do
        should contain_class('swift::proxy::cache').with(
          'memcache_servers' => memcached_servers,
        )
      end

      it 'should configure swift on separate partition' do
        should contain_file(swift_partition).with(
          'ensure' => 'directory',
          'owner'  => 'swift',
          'group'  => 'swift',
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end

