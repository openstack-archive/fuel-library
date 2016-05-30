# ROLE: primary-controller
# ROLE: controller
require 'spec_helper'
require 'shared-examples'
manifest = 'swift/proxy_storage.pp'

describe manifest do
  shared_examples 'catalog' do
    workers_max      = Noop.hiera 'workers_max'
    role             = Noop.hiera 'role'
    storage_hash     = Noop.hiera_hash 'storage'
    swift_hash       = Noop.hiera_hash 'swift'
    network_scheme   = Noop.hiera_hash 'network_scheme'
    network_metadata = Noop.hiera_hash 'network_metadata'

    memcached_nodes     = Noop.puppet_function('get_nodes_hash_by_roles', network_metadata, ['primary-controller', 'controller'])
    memcached_addresses = Noop.hiera 'memcached_addresses'
    memcached_port      = Noop.hiera 'memcache_server_port', '11211'
    memcached_servers   = memcached_addresses.map{ |n| n = n + ':' + memcached_port }

    swift_operator_roles = storage_hash.fetch('swift_operator_roles', ['admin', 'SwiftOperator', '_member_'])
    ring_part_power = swift_hash.fetch('ring_part_power', 10)
    ring_min_part_hours = Noop.hiera 'swift_ring_min_part_hours', 1
    deploy_swift_proxy = Noop.hiera('deploy_swift_proxy')
    deploy_swift_storage = Noop.hiera('deploy_swift_storage')
    swift_proxies_num  = (Noop.hiera('swift_proxies')).size
    rabbit_hosts       = Noop.hiera('amqp_hosts')
    rabbit_user        = Noop.hiera_structure('rabbit/user', 'nova')
    rabbit_password    = Noop.hiera_structure('rabbit/password')
    network_scheme     = Noop.hiera_hash 'network_scheme'
    internal_virtual_ip = Noop.hiera_structure('network_metadata/vips/management/ipaddr')

    if swift_proxies_num < 2
      ring_replicas = 2
    else
      ring_replicas = 3
    end

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

    let(:public_ssl_hash) { Noop.hiera_hash 'public_ssl' }

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
    let(:swift_public_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,public_ssl_hash,'swift','public','protocol','http' }
    let(:swift_public_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,public_ssl_hash,'swift','public','hostname',[Noop.hiera('swift_endpoint', ''), public_vip] }

    # Swift
    if !(storage_hash['images_ceph'] and storage_hash['objects_ceph']) and !storage_hash['images_vcenter']
      swift_partition = Noop.hiera 'swift_partition'
      if role == 'primary-controller'
        ['account', 'object', 'container'].each do | ring |
          it "should run rebalancing swift #{ring} ring" do
            should contain_exec("rebalance_#{ring}").with(
              'command' => "swift-ring-builder /etc/swift/#{ring}.builder rebalance",
              'user'    => 'swift',
              'returns' => [0,1],
            )
            should contain_exec("create_#{ring}").with(
              'command' => "swift-ring-builder /etc/swift/#{ring}.builder create #{ring_part_power} #{ring_replicas} #{ring_min_part_hours}",
              'user'    => 'swift',
            )
          end
        end
        ['account', 'object', 'container'].each do | ring |
          it "should define swift::ringbuilder::rebalance[#{ring}] before swift proxy service" do
            should contain_swift__ringbuilder__rebalance(ring).that_comes_before('Service[swift-proxy-server]')
          end
        end
        ['account', 'object', 'container'].each do | ring |
          ['account', 'object', 'container'].each do | storage |
            it "should define swift::ringbuilder::rebalance[#{ring}] before swift::storage::generic[#{storage}]" do
#              expect(graph).to ensure_transitive_dependency("Swift::Ringbuilder::Rebalance[#{ring}]",
#                                                            "Swift::Storage::Generic[#{storage}]")
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

      if !swift_partition
        swift_partition = '/var/lib/glance/node'
        it 'should allow swift user to write into /var/lib/glance directory' do
          should contain_file('/var/lib/glance').with(
            'ensure' => 'directory',
            'group'  => 'swift',
          ).that_requires('Package[swift]')
        end
      end

      it 'should disable mount check for swift devices' do
        should contain_class('swift::storage::all').with('mount_check' => false)
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

      it 'should contain container_sync class' do
        should contain_class('swift::proxy::container_sync')
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

    if deploy_swift_proxy or deploy_swift_storage
      realm1_key = Noop.hiera('swift_realm1_key', 'realm1key')
      cluster_name1_endpoint = "#{swift_public_protocol}://#{swift_public_address}:8080/v1"
      it 'should contain swift_container-sync-realms config' do
        should contain_swift_container_sync_realms_config('realm1/key').with_value(realm1_key)
        should contain_swift_container_sync_realms_config('realm1/cluster_name1').with_value(cluster_name1_endpoint)
      end
    end
  end
  test_ubuntu_and_centos manifest
end
