require 'spec_helper'
require 'shared-examples'
manifest = 'swift/swift.pp'

describe manifest do
  shared_examples 'catalog' do
    workers_max = Noop.hiera 'workers_max'
    role = Noop.hiera 'role'
    storage_hash = Noop.hiera 'storage'
    swift_hash = Noop.hiera 'swift'
    network_scheme     = Noop.hiera_hash 'network_scheme'
    network_metadata     = Noop.hiera_hash 'network_metadata'

    memcached_nodes = Noop.puppet_function('get_nodes_hash_by_roles', network_metadata, ['primary-controller', 'controller'])
    memcached_addresses = Noop.puppet_function('get_node_to_ipaddr_map_by_network_role', memcached_nodes, 'mgmt/memcache').values
    memcached_servers = memcached_addresses.sort.map{ |n| n = n + ':11211' }


    swift_operator_roles = storage_hash.fetch('swift_operator_roles', ['admin', 'SwiftOperator'])
    ring_part_power = swift_hash.fetch('ring_part_power', 10)
    ring_min_part_hours = Noop.hiera 'swift_ring_min_part_hours', 1
    deploy_swift_proxy = Noop.hiera('deploy_swift_proxy')
    rabbit_hosts       = Noop.hiera('amqp_hosts')
    rabbit_user        = Noop.hiera_structure('rabbit/user', 'nova')
    rabbit_password    = Noop.hiera_structure('rabbit/password')
    network_scheme     = Noop.hiera_hash 'network_scheme'

    let (:storage_nets){
        Noop.puppet_function 'get_routable_networks_for_network_role', network_scheme, 'swift/replication', ' '
    }

    let (:mgmt_nets){
        Noop.puppet_function 'get_routable_networks_for_network_role', network_scheme, 'swift/api', ' '
    }

    let (:bind_to_one) {
      api_ip = Noop.puppet_function 'get_network_role_property', 'swift/api', 'ipaddr'
      storage_ip = Noop.puppet_function 'get_network_role_property', 'swift/replication', 'ipaddr'
      api_ip == storage_ip
    }

    let(:ssl_hash) { Noop.hiera_hash 'use_ssl' }

    let(:internal_auth_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','protocol','http' }

    let(:internal_auth_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','hostname',[Noop.hiera('service_endpoint', ''), management_vip] }

    let(:admin_auth_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin','protocol','http' }

    let(:admin_auth_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin','hostname',[Noop.hiera('service_endpoint', ''), management_vip] }

    let(:auth_uri) { "#{internal_auth_protocol}://#{internal_auth_address}:5000/" }

    let(:identity_uri) { "#{admin_auth_protocol}://#{admin_auth_address}:35357/" }

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
          it "should define swift::ringbuilder::rebalance[#{ring}] before swift proxy service" do
            should contain_swift__ringbuilder__rebalance(ring).that_comes_before('Service[swift-proxy-server]')
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

      it 'should disable mount check for swift devices' do
        should contain_class('swift::storage::all').with('mount_check' => false)
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
            if bind_to_one
              should contain_class('swift::dispersion').with(
                'auth_url' => "https://#{keystone_endpoint}:5000/v2.0/"
              ).that_requires('Class[openstack::swift::status]')
            else
              should contain_class('swift::dispersion').with(
                'auth_url' => "https://#{keystone_endpoint}:5000/v2.0/"
              ).that_requires('Class[openstack::swift::proxy]')
            end
          end
        end

        context 'with enabled internal TLS for swift' do
          swift_endpoint = Noop.hiera_structure 'use_ssl/swift_internal_hostname'
            it {
              if bind_to_one
                should contain_class('openstack::swift::status').with(
                  'endpoint'  => "https://#{swift_endpoint}:8080",
                  'only_from' => "127.0.0.1 240.0.0.2 #{storage_nets} #{mgmt_nets}",
                ).that_comes_before('Class[swift::dispersion]')
              else
                should_not contain_class('openstack::swift::status')
              end
            }
        end
      else
        keystone_endpoint = Noop.hiera 'service_endpoint'
        context 'with disabled internal TLS for keystone' do
          it 'should declare swift::dispersion' do
            if bind_to_one
            should contain_class('swift::dispersion').with(
              'auth_url' => "http://#{keystone_endpoint}:5000/v2.0/"
            ).that_requires('Class[openstack::swift::status]')
            else
            should contain_class('swift::dispersion').with(
              'auth_url' => "http://#{keystone_endpoint}:5000/v2.0/"
            ).that_requires('Class[openstack::swift::proxy]')
            end
          end
        end

        context 'with disabled internal TLS for swift' do
          it {
            if bind_to_one
            should contain_class('openstack::swift::status').with(
              'only_from' => "127.0.0.1 240.0.0.2 #{storage_nets} #{mgmt_nets}",
            ).that_comes_before('Class[swift::dispersion]')
            else
              should_not contain_class('openstack::swift::status')
            end
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

      it 'should contain valid auth uris' do
        should contain_class('swift::proxy::authtoken').with(
          'auth_uri'     => auth_uri,
          'identity_uri' => identity_uri,
        )
      end

      it 'should contain swift backups section in rsync conf' do
        should contain rsync__server__module('swift_backups').with(
          'path'            => '/etc/swift',
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

