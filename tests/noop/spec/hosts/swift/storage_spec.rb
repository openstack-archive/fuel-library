# RUN: neut_vlan.ceph.ceil-primary-controller.overridden_ssl ubuntu
# RUN: neut_vlan.ceph.controller-ephemeral-ceph ubuntu
# RUN: neut_vlan.ironic.controller ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-controller ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl ubuntu

require 'spec_helper'
require 'shared-examples'
manifest = 'swift/storage.pp'

describe manifest do
  shared_examples 'catalog' do
    network_scheme         = Noop.hiera_structure 'network_scheme', {}
    network_metadata       = Noop.hiera_structure 'network_metadata', {}

    let(:prepare) do
      Noop.puppet_function 'prepare_network_config', network_scheme
    end

    storage_hash           = Noop.hiera_hash 'storage'
    swift_hash             = Noop.hiera_hash 'swift'
    rabbit_hosts           = Noop.hiera 'amqp_hosts'
    rabbit_user            = Noop.hiera_structure 'rabbit/user', 'nova'
    rabbit_password        = Noop.hiera_structure 'rabbit/password'
    network_scheme         = Noop.hiera_hash 'network_scheme'
    swift_master_role      = Noop.hiera 'swift_master_role', 'primary-controller'
    is_primary_swift_proxy = Noop.hiera 'is_primary_swift_proxy', false
    mp_hash                = Noop.hiera 'mp'
    swift_storage_ipaddr   = Noop.puppet_function 'get_network_role_property', 'swift/replication', 'ipaddr'
    debug                  = Noop.puppet_function 'pick', swift_hash['debug'], Hiera.noop('debug', false)
    verbose                = Noop.puppet_function 'pick', swift_hash['verbose'], Hiera.noop('verbose', false)
    deploy_swift_storage   = Noop.hiera 'deploy_swift_storage', true

    # Swift
    if !(storage_hash['images_ceph'] and storage_hash['objects_ceph']) and !storage_hash['images_vcenter']
      swift_partition = Noop.hiera 'swift_partition', '/var/lib/glance/node'
      master_swift_proxy_nodes      = Noop.puppet_function 'get_nodes_hash_by_roles', network_metadata, [swift_master_role]
      master_swift_proxy_nodes_list = Noop.puppet_function 'values', master_swift_proxy_nodes
      master_swift_proxy_ip         = Noop.puppet_function 'regsubst', master_swift_proxy_nodes_list[0]['network_roles']['swift/api'], '\/\d+$', ''
      master_swift_replication_ip   = Noop.puppet_function 'regsubst', master_swift_proxy_nodes_list[0]['network_roles']['swift/replication'], '\/\d+$', ''

      if deploy_swift_storage
        it 'should allow swift user to write into /var/lib/glance directory' do
          should contain_file('/var/lib/glance').with(
            'ensure' => 'directory',
            'group'  => 'swift',
          ).that_requires('Package[swift]')
        end
      end

      it 'should contain openstack::swift::storage_node' do
        should contain_class('openstack::swift::storage_node').with(
          :storage_type                => false,
          :loopback_size               => '5243780',
          :storage_mnt_base_dir        => swift_partition,
          :storage_devices             => Noop.puppet_function('filter_hash', mp_hash, 'point'),
          :swift_zone                  => master_swift_proxy_nodes_list[0]['swift_zone'],
          :swift_local_net_ip          => swift_storage_ipaddr,
          :master_swift_proxy_ip       => master_swift_proxy_ip,
          :master_swift_replication_ip => master_swift_replication_ip,
          :sync_rings                  => ! is_primary_swift_proxy,
          :debug                       => debug,
          :verbose                     => verbose,
          :log_facility                => 'LOG_SYSLOG',
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end
