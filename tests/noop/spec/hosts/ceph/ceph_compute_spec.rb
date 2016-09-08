# ROLE: compute

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
        ).that_requires('Class[ceph]')
      end

      it 'should add admin key' do
        should contain_ceph__key('client.admin').with(
          'secret'  => admin_key,
          'cap_mon' => 'allow *',
          'cap_osd' => 'allow *',
          'cap_mds' => 'allow',
        )
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
