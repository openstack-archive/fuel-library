require 'spec_helper'
require 'shared-examples'
manifest = 'swift/swift.pp'

describe manifest do
  shared_examples 'catalog' do
    workers_max = Noop.hiera 'workers_max'
    role = Noop.hiera 'role'
    storage_hash = Noop.hiera 'storage'
    swift_hash = Noop.hiera 'swift'
    nodes = Noop.hiera 'nodes'
    primary_controller_nodes = Noop.puppet_function('filter_nodes', nodes, 'role','primary-controller')
    controllers = primary_controller_nodes + Noop.puppet_function('filter_nodes', nodes, 'role', 'controller')
    controller_internal_addresses = Noop.puppet_function('nodes_to_hash', controllers,'name','internal_address')
    controller_nodes = Noop.puppet_function('ipsort', controller_internal_addresses.values)
    swift_operator_roles = storage_hash.fetch('swift_operator_roles', ['admin', 'SwiftOperator', '_member_'])
    ring_part_power = swift_hash.fetch('ring_part_power', 10)
    ring_min_part_hours = Noop.hiera 'swift_ring_min_part_hours', 1
    memcached_servers = controller_nodes.map{ |n| n = n + ':11211' }
    deploy_swift_proxy = Noop.hiera('deploy_swift_proxy')
    rabbit_hosts       = Noop.hiera('amqp_hosts')
    rabbit_user        = Noop.hiera_structure('rabbit/user', 'nova')
    rabbit_password    = Noop.hiera_structure('rabbit/password')
    network_scheme     = Noop.hiera 'network_scheme'
    internal_virtual_ip = Noop.hiera_structure('network_metadata/vips/management/ipaddr')

    let (:storage_nets){
        Noop.puppet_function 'get_routable_networks_for_network_role', network_scheme, 'swift/replication', ' '
    }

    let (:mgmt_nets){
        Noop.puppet_function 'get_routable_networks_for_network_role', network_scheme, 'swift/api', ' '
    }

    let (:bind_to_one) {
      api_net = Noop.puppet_function 'get_network_role_property', 'swift/api', 'network'
      Noop.puppet_function 'has_ip_in_network', internal_virtual_ip, api_net
    }

    let(:ssl_hash) { Noop.hiera_hash 'use_ssl' }

    let(:internal_auth_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','protocol','http' }

    let(:internal_auth_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','hostname',[Noop.hiera('service_endpoint', ''), management_vip] }

    let(:admin_auth_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin','protocol','http' }

    let(:admin_auth_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin','hostname',[Noop.hiera('service_endpoint', ''), management_vip] }

    let(:auth_uri) { "#{internal_auth_protocol}://#{internal_auth_address}:5000/" }

    let(:identity_uri) { "#{admin_auth_protocol}://#{admin_auth_address}:35357/" }

    let(:proxy_port) { Noop.hiera 'proxy_port', '8080' }
    let(:swift_api_ipaddr) { Noop.puppet_function 'get_network_role_property', 'swift/api', 'ipaddr' }
    let(:swift_internal_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'swift','internal','protocol','http' }
    let(:swift_interal_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'swift','internal','hostname',[swift_api_ipaddr, management_vip] }

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

      it 'should configure swift on separate partition' do
        should contain_file(swift_partition).with(
          'ensure' => 'directory',
          'owner'  => 'swift',
          'group'  => 'swift',
        )
      end

      it 'should configure proxy workers' do
        fallback_workers = [[facts[:processorcount].to_i, 2].max, workers_max.to_i].min
        workers = swift_hash.fetch('workers', fallback_workers)
        should contain_class('swift::proxy').with(
          'workers' => workers)
      end

      it 'should declare swift::proxy class with 4 processess on 4 CPU & 32G system' do
        should contain_class('swift::proxy').with(
          'workers' => '4',
        )
      end
    end
    if deploy_swift_proxy
      it 'should configure proxy workers' do
        fallback_workers = [[facts[:processorcount].to_i, 2].max, workers_max.to_i].min
        workers = swift_hash.fetch('workers', fallback_workers)
        should contain_class('swift::proxy').with(
          'workers' => workers)
      end

      it 'should declare swift::proxy class with 4 processess on 4 CPU & 32G system' do
        should contain_class('swift::proxy').with(
          'workers' => '4',
        )
      end

      it 'should contain rabbit params' do
        should contain_class('openstack::swift::proxy').with(
          :rabbit_user     => rabbit_user,
          :rabbit_password => rabbit_password,
          :rabbit_hosts    => rabbit_hosts.split(', '),
        )
      end

      it 'should configure health check service correctly' do
        if !bind_to_one
          should_not contain_class('openstack::swift:status').with(
            :endpoint    => "#{swift_internal_protocol}://#{swift_internal_address}:#{proxy_port}",
            :scan_target => "#{internal_auth_address}:5000",
            :only_from   => "127.0.0.1 240.0.0.2 #{storage_nets} #{mgmt_nets}",
            :con_timeout => 5
          ).that_comes_before('Class[swift::dispersion]')
        else
          should_not contain_class('openstack::swift:status')
        end
      end

      it 'should contain valid auth uris' do
        should contain_class('swift::proxy::authtoken').with(
          'auth_uri'     => auth_uri,
          'identity_uri' => identity_uri,
        )
      end

      it 'should contain swift backups section in rsync conf' do
        should contain rsync__server__module('swift_backups').with(
          'path'            => '/etc/swift/backups',
          'lock_file'       => '/var/lock/swift_backups.lock',
          'uid'             => 'swift',
          'gid'             => 'swift',
          'incoming_chmod'  => false,
          'outgoing_chmod'  => false,
          'max_connections' => '5',
          'read_only'       => true,
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end

