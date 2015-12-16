require 'spec_helper'
require 'shared-examples'
manifest = 'ceph/ceph_compute.pp'

describe manifest do
  shared_examples 'catalog' do
    storage_hash = Noop.hiera_hash 'storage'

    if (storage_hash['ephemeral_ceph'])
      libvirt_images_type = 'rbd'
    else
      libvirt_images_type = 'default'
    end

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
<<<<<<< HEAD
      it { should contain_class('ceph').with(
           'osd_pool_default_size'    => storage_hash['osd_pool_size'],
           'osd_pool_default_pg_num'  => storage_hash['pg_num'],
           'osd_pool_default_pgp_num' => storage_hash['pg_num'],)
         }
      it { should contain_class('ceph::conf') }

      it { should contain_ceph__pool('compute').with(
          'pg_num'        => storage_hash['per_pool_pg_nums']['compute'],
          'pgp_num'       => storage_hash['per_pool_pg_nums']['compute'],)
        }
      it { should contain_class('ceph::ephemeral').with(
        'libvirt_images_type' => libvirt_images_type,)
      }
      it { should contain_ceph__pool('compute').that_requires('Class[ceph::conf]') }
      it { should contain_ceph__pool('compute').that_comes_before('Class[ceph::nova_compute]') }
      it { should contain_class('ceph::nova_compute').that_requires('Ceph::Pool[compute]') }
      it { should contain_exec('Set Ceph RBD secret for Nova').that_requires('Service[libvirt]')}
    else
      it { should_not contain_class('ceph') }
=======

      it 'should deploy ceph' do
        should contain_class('ceph').with(
          'fsid'                => fsid,
          'mon_initial_members' => mon_ips,
          'mon_host'            => mon_hosts,
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

      it { should contain_class('osnailyfacter::ceph_nova_compute') }

      if storage_hash['ephemeral_ceph']
        it 'should configure nova compute for ceph' do
          should contain_nova_config('libvirt/images_type').with(:value => libvirt_images_type).that_requires('ceph')
          should contain_nova_config('libvirt/inject_key').with(:value => false).that_requires('ceph')
          should contain_nova_config('libvirt/inject_partition').with(:value => '-2').that_requires('ceph')
          should contain_nova_config('libvirt/images_rbd_pool').with(:value => compute_pool).that_requires('ceph')
        end
      end 
>>>>>>> 5744cfa... Moving to upstream ceph
    end
  end
  test_ubuntu_and_centos manifest
end
