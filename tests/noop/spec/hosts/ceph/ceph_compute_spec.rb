# ROLE: compute

require 'spec_helper'
require 'shared-examples'
manifest = 'ceph/ceph_compute.pp'

describe manifest do
  shared_examples 'catalog' do
    storage_hash = Noop.hiera 'storage'

    let(:mon_key) do
      Noop.hiera_structure 'storage/mon_key', 'AQDesGZSsC7KJBAAw+W/Z4eGSQGAIbxWjxjvfw=='
    end

    let(:fsid) do
      Noop.hiera_structure 'storage/fsid', '066F558C-6789-4A93-AAF1-5AF1BA01A3AD'
    end

    let(:cinder_pool) do
      'volumes'
    end

    let(:glance_pool) do
      'images'
    end

    let(:compute_pool) do
      'compute'
    end

    let(:compute_user) do
      'compute'
    end

    let(:libvirt_images_type) do
      'rbd'
    end

    let(:secret) do
      Noop.hiera_structure 'storage/mon_key', 'AQDesGZSsC7KJBAAw+W/Z4eGSQGAIbxWjxjvfw=='
    end

    let(:per_pool_pg_nums) do
      storage_hash['per_pool_pg_nums']
    end

    let(:compute_pool_pg_nums) do
      Noop.hiera_structure 'storage/per_pool_pg_nums/compute', '1024'
    end

    let(:compute_pool_pgp_nums) do
      Noop.hiera_structure 'storage/per_pool_pg_nums/compute', '1024'
    end

    let(:network_scheme) do
      Noop.hiera_hash 'network_scheme'
    end

    let(:prepare_network_config) do
      Noop.puppet_function 'prepare_network_config', network_scheme
    end

    let(:ceph_cluster_network) do
      Noop.puppet_function 'get_network_role_property', 'ceph/replication', 'network'
    end

    let(:ceph_public_network) do
      Noop.puppet_function 'get_network_role_property', 'ceph/public', 'network'
    end

    let(:ceph_monitor_nodes) do
      Noop.hiera_hash('ceph_monitor_nodes')
    end

    let(:mon_address_map) do
      Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', ceph_monitor_nodes, 'ceph/public'
    end

    let(:mon_ips) do
      mon_address_map.values.join(',')
    end

    let(:mon_hosts) do
      mon_address_map.keys.join(',')
    end

    if (storage_hash['volumes_ceph'] or
        storage_hash['images_ceph'] or
        storage_hash['objects_ceph'] or
        storage_hash['ephemeral_ceph']
       )
      it 'should deploy ceph' do
        should contain_class('ceph').with(
          'fsid'                => fsid,
          'mon_initial_members' => mon_hosts,
          'mon_host'            => mon_ips,
          'cluster_network'     => ceph_cluster_network,
          'public_network'      => ceph_public_network,
        )
      end

      it 'should configure compute pool' do 
        should contain_ceph__pool(compute_pool).with(
          'pg_num'  => compute_pool_pg_nums,
          'pgp_num' => compute_pool_pgp_nums,
        ).that_requires('ceph')
      end

      it 'should configure ceph compute keys' do
        should contain_ceph__key("client.#{compute_user}").with(
          'secret'  => secret,
          'cap_mon' => 'allow r',
          'cap_osd' => "allow class-read object_prefix rbd_children, allow rwx pool=#{cinder_pool}, allow rx pool=#{glance_pool}, allow rwx pool=#{compute_pool}",
          'inject'  => true,
        )
      end

      it 'should contain class osnailyfacter::ceph_nova_compute' do
        should contain_class('osnailyfacter::ceph_nova_compute').with(
          'user'                => compute_user,
          'compute_pool'        => compute_pool,
          'libvirt_images_type' => libvirt_images_type,
        )
      end 
    end
  end
  test_ubuntu_and_centos manifest
end
