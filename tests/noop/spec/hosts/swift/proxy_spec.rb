# RUN: neut_vlan.ceph.ceil-primary-controller.overridden_ssl ubuntu
# RUN: neut_vlan.ceph.controller-ephemeral-ceph ubuntu
# RUN: neut_vlan.ironic.controller ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-controller ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl ubuntu

require 'spec_helper'
require 'shared-examples'
manifest = 'swift/proxy.pp'

describe manifest do
  shared_examples 'catalog' do
    network_scheme         = Noop.hiera_structure 'network_scheme', {}
    network_metadata       = Noop.hiera_structure 'network_metadata', {}

    let(:swift_storage_ipaddr) do
      prepare
      Noop.puppet_function 'get_network_role_property', 'swift/replication', 'ipaddr'
    end

    let(:swift_api_ipaddr) do
      prepare
      Noop.puppet_function 'get_network_role_property', 'swift/api', 'ipaddr'
    end

    workers_max      = Noop.hiera 'workers_max', 16
    role             = Noop.hiera 'role'
    storage_hash     = Noop.hiera_hash 'storage'
    swift_hash       = Noop.hiera_hash 'swift'

    memcached_nodes     = Noop.puppet_function('get_nodes_hash_by_roles', network_metadata, ['primary-controller', 'controller'])
    memcached_addresses = Noop.hiera 'memcached_addresses'
    memcached_port      = Noop.hiera 'memcache_server_port', '11211'
    memcached_servers   = memcached_addresses.sort.map{ |n| n = n + ':' + memcached_port }

    swift_operator_roles = storage_hash.fetch('swift_operator_roles', ['admin', 'SwiftOperator'])
    ring_part_power = swift_hash.fetch('ring_part_power', 10)
    ring_min_part_hours = Noop.hiera 'swift_ring_min_part_hours', 1
    deploy_swift_proxy = Noop.hiera('deploy_swift_proxy', true)
    swift_proxies_num  = (Noop.hiera('swift_proxies')).size
    rabbit_hosts       = Noop.hiera('amqp_hosts')
    rabbit_user        = Noop.hiera_structure('rabbit/user', 'nova')
    rabbit_password    = Noop.hiera_structure('rabbit/password')

    swift_master_role       = Noop.hiera 'swift_master_role', 'primary-controller'
    swift_nodes             = Noop.hiera_hash 'swift_nodes', {}
    swift_proxies_addr_list = Noop.puppet_function('values',
      Noop.puppet_function('get_node_to_ipaddr_map_by_network_role',
        Noop.hiera_hash('swift_proxies', {}), 'swift/api'))
    is_primary_swift_proxy  = Noop.hiera 'is_primary_swift_proxy', false
    proxy_port              = Noop.hiera 'proxy_port', '8080'
    management_vip          = Noop.hiera 'management_vip'
    debug                   = Noop.puppet_function 'pick', swift_hash['debug'], Noop.hiera('debug', false)
    verbose                 = Noop.puppet_function 'pick', swift_hash['verbose'], Noop.hiera('verbose', false)
    keystone_user           = Noop.puppet_function 'pick', swift_hash['user'], 'swift'
    keystone_password       = Noop.puppet_function 'pick', swift_hash['user_password'], 'passsword'
    keystone_tenant         = Noop.puppet_function 'pick', swift_hash['tenant'], 'services'
    rabbit_hash             = Noop.hiera_hash 'rabbit'

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
      swift_api_ipaddr == swift_storage_ipaddr
    }

    let(:ssl_hash) { Noop.hiera_hash 'use_ssl', {} }

    let(:internal_auth_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','protocol','http' }

    let(:internal_auth_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','hostname',[Noop.hiera('service_endpoint', ''), management_vip] }

    let(:admin_auth_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin','protocol','http' }

    let(:admin_auth_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin','hostname',[Noop.hiera('service_endpoint', ''), management_vip] }

    let(:auth_uri) { "#{internal_auth_protocol}://#{internal_auth_address}:5000/" }

    let(:identity_uri) { "#{admin_auth_protocol}://#{admin_auth_address}:35357/" }

    # Swift
    if !(storage_hash['images_ceph'] and storage_hash['objects_ceph']) and !storage_hash['images_vcenter']
      master_swift_proxy_nodes      = Noop.puppet_function 'get_nodes_hash_by_roles', network_metadata, [swift_master_role]
      master_swift_proxy_nodes_list = Noop.puppet_function 'values', master_swift_proxy_nodes
      master_swift_proxy_ip         = Noop.puppet_function 'regsubst', master_swift_proxy_nodes_list[0]['network_roles']['swift/api'], '\/\d+$', ''
      master_swift_replication_ip   = Noop.puppet_function 'regsubst', master_swift_proxy_nodes_list[0]['network_roles']['swift/replication'], '\/\d+$', ''

      if is_primary_swift_proxy
        # FIXME(bogdando) there is no is_primary_swift_proxy in YAML templates
        xit 'should contain ring_devices' do
          should contain_ring__devices('all').with(
            :storages => swift_nodes
          ).that_requires('Class[swift]')
        end
      end

      if $deploy_swift_proxy
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

        it 'should declare swift::dispersion' do
            should contain_class('openstack_tasks::swift::proxy::swift::dispersion').with(
              :auth_url       => "#{internal_auth_protocol}://#{internal_auth_address}:5000/v2.0/",
              :auth_user      =>  keystone_user,
              :auth_tenant    =>  keystone_tenant,
              :auth_pass      =>  keystone_password,
              :auth_version   =>  '2.0',
            ).that_requires('Class[openstack_tasks::swift::proxy::openstack::swift::status]')
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

        it 'contains storage node class' do
          should contain_class('openstack_tasks::swift::proxy::openstack::swift::proxy').with(
            :swift_user_password            => swift_hash['user_password'],
            :swift_operator_roles           => swift_operator_roles,
            :swift_proxies_cache            => memcached_addresses,
            :cache_server_port              => Hera.noop('memcache_server_port', '11211'),
            :ring_part_power                => ring_part_power,
            :ring_replicas                  => ring_replicas,
            :primary_proxy                  => is_primary_swift_proxy,
            :swift_proxy_local_ipaddr       => swift_api_ipaddr,
            :swift_replication_local_ipaddr => swift_storage_ipaddr,
            :master_swift_proxy_ip          => master_swift_proxy_ip,
            :master_swift_replication_ip    => master_swift_replication_ip,
            :proxy_port                     => proxy_port,
            :proxy_workers                  => service_workers,
            :debug                          => debug,
            :verbose                        => verbose,
            :log_facility                   => 'LOG_SYSLOG',
            :ceilometer                     => Hiera.noop('use_ceilometer',false),
            :ring_min_part_hours            => ring_min_part_hours,
            :admin_user                     => keystone_user,
            :admin_tenant_name              => keystone_tenant,
            :admin_password                 => keystone_password,
            :auth_host                      => internal_auth_address,
            :auth_protocol                  => internal_auth_protocol,
            :auth_uri                       => auth_uri,
            :identity_uri                   => identity_uri,
            :rabbit_user                    => rabbit_hash['user'],
            :rabbit_password                => rabbit_hash['password'],
            :rabbit_hosts                   => split(rabbit_hosts, ', '),
          )
        end
      end
    end
  end
  test_ubuntu_and_centos manifest
end
