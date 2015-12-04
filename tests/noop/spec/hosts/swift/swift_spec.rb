require 'spec_helper'
require 'shared-examples'
manifest = 'swift/swift.pp'

describe manifest do
  shared_examples 'catalog' do
    role = Noop.hiera 'role'
    storage_hash = Noop.hiera 'storage'
    swift_hash = Noop.hiera 'swift'
    nodes = Noop.hiera 'nodes'
    primary_controller_nodes = Noop.puppet_function('filter_nodes', nodes, 'role','primary-controller')
    controllers = primary_controller_nodes + Noop.puppet_function('filter_nodes', nodes, 'role', 'controller')
    controller_internal_addresses = Noop.puppet_function('nodes_to_hash', controllers,'name','internal_address')
    controller_nodes = Noop.puppet_function('ipsort', controller_internal_addresses.values)
    swift_operator_roles = storage_hash.fetch('swift_operator_roles', ['admin', 'SwiftOperator'])
    ring_part_power = swift_hash.fetch('ring_part_power', 10)
    ring_min_part_hours = Noop.hiera 'swift_ring_min_part_hours', 1
    memcached_servers = controller_nodes.map{ |n| n = n + ':11211' }
    deploy_swift_proxy = Noop.hiera('deploy_swift_proxy')
    rabbit_hosts       = Noop.hiera('amqp_hosts')
    rabbit_user        = Noop.hiera_structure('rabbit/user', 'nova')
    rabbit_password    = Noop.hiera_structure('rabbit/password')
    let (:sto_nets){
        network_scheme = Noop.hiera 'network_scheme'
        sto_nets = Noop.puppet_function 'get_routable_networks_for_network_role', network_scheme, 'swift/replication', ' '
    }
    let (:man_nets){
        network_scheme = Noop.hiera 'network_scheme'
        man_nets = Noop.puppet_function 'get_routable_networks_for_network_role', network_scheme, 'swift/api', ' '
    }

    # Swift
    if !(storage_hash['images_ceph'] and storage_hash['objects_ceph']) and !storage_hash['images_vcenter']
      swift_partition = Noop.hiera 'swift_partition'
      if !swift_partition
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
          it "should run rebalancing swift #{ring} ring" do
            should contain_exec("rebalance_#{ring}").with(
              'command' => "swift-ring-builder /etc/swift/#{ring}.builder rebalance",
              'user'    => 'swift',
              'returns' => [0,1],
            )
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
        ).that_comes_before('Class[swift::proxy]')
      end

      it 'should declare swift::proxy::cache class with correct memcache_servers parameter' do
        should contain_class('swift::proxy::cache').with(
          'memcache_servers' => memcached_servers,
        )
      end

      it 'should declare class swift::proxy::keystone with correct operator_roles parameter' do
        should contain_class('swift::proxy::keystone').with(
          'operator_roles' => swift_operator_roles,
        )
      end

      if Noop.hiera('use_ssl', false)
        context 'with enabled internal TLS for keystone' do
          keystone_endpoint = Noop.hiera_structure 'use_ssl/keystone_internal_hostname'
          it 'should declare swift::dispersion' do
            should contain_class('swift::dispersion').with(
              'auth_url' => "https://#{keystone_endpoint}:5000/v2.0/"
            ).that_requires('Class[openstack::swift::status]')
          end
        end

        context 'with enabled internal TLS for swift' do
          swift_endpoint = Noop.hiera_structure 'use_ssl/swift_internal_hostname'
          it {
            should contain_class('openstack::swift::status').with(
              'endpoint'  => "https://#{swift_endpoint}:8080",
              'only_from' => "127.0.0.1 240.0.0.2 #{sto_nets} #{man_nets}",
            ).that_requires('Class[openstack::swift::proxy]')
          }
        end
      else
        keystone_endpoint = Noop.hiera 'service_endpoint'
        context 'with disabled internal TLS for keystone' do
          it 'should declare swift::dispersion' do
            should contain_class('swift::dispersion').with(
              'auth_url' => "http://#{keystone_endpoint}:5000/v2.0/"
            ).that_requires('Class[openstack::swift::status]')
          end
        end

        context 'with disabled internal TLS for swift' do
          it {
            should contain_class('openstack::swift::status').with(
              'only_from' => "127.0.0.1 240.0.0.2 #{sto_nets} #{man_nets}",
            ).that_requires('Class[openstack::swift::proxy]')
          }
        end
      end

      it 'should configure swift on separate partition' do
        should contain_file(swift_partition).with(
          'ensure' => 'directory',
          'owner'  => 'swift',
          'group'  => 'swift',
        )
      end
    end
    if deploy_swift_proxy
      it 'should contain rabbit params' do
        should contain_class('openstack::swift::proxy').with(
          :rabbit_user     => rabbit_user,
          :rabbit_password => rabbit_password,
          :rabbit_hosts    => rabbit_hosts.split(', '),
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end

