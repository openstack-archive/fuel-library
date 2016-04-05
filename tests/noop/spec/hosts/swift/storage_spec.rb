# HIERA: neut_tun.ceph.murano.sahara.ceil-controller
# HIERA: neut_tun.ceph.murano.sahara.ceil-primary-controller
# HIERA: neut_tun.ironic-primary-controller
# HIERA: neut_tun.l3ha-primary-controller
# HIERA: neut_vlan.ceph-primary-controller
# HIERA: neut_vlan.dvr-primary-controller
# HIERA: neut_vlan.murano.sahara.ceil-controller
# HIERA: neut_vlan.murano.sahara.ceil-primary-controller
require 'spec_helper'
require 'shared-examples'
manifest = 'swift/storage.pp'

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
    memcached_servers   = memcached_addresses.sort.map{ |n| n = n + ':' + memcached_port }

    swift_operator_roles = storage_hash.fetch('swift_operator_roles', ['admin', 'SwiftOperator'])
    ring_part_power = swift_hash.fetch('ring_part_power', 10)
    ring_min_part_hours = Noop.hiera 'swift_ring_min_part_hours', 1
    deploy_swift_proxy = Noop.hiera('deploy_swift_proxy')
    swift_proxies_num  = (Noop.hiera('swift_proxies')).size
    rabbit_hosts       = Noop.hiera('amqp_hosts')
    rabbit_user        = Noop.hiera_structure('rabbit/user', 'nova')
    rabbit_password    = Noop.hiera_structure('rabbit/password')
    network_scheme     = Noop.hiera_hash 'network_scheme'

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
  end
  test_ubuntu_and_centos manifest
end

