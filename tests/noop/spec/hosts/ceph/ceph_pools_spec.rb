# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'ceph/ceph_pools.pp'

describe manifest do
  shared_examples 'catalog' do
    storage_hash = Noop.hiera 'storage'

    let(:mon_key) do
      Noop.hiera_structure 'storage/mon_key', 'AQDesGZSsC7KJBAAw+W/Z4eGSQGAIbxWjxjvfw=='
    end

    let(:fsid) do
      Noop.hiera_structure 'storage/fsid', '066F558C-6789-4A93-AAF1-5AF1BA01A3AD'
    end

    let(:cinder_user) do
      'volumes'
    end

    let(:cinder_pool) do
      'volumes'
    end

    let(:cinder_backup_user) do
      'backups'
    end

    let(:cinder_backup_pool) do
      'backups'
    end

    let(:glance_user) do
      'images'
    end

    let(:glance_pool) do
      'images'
    end

    if (storage_hash['images_ceph'] or storage_hash['objects_ceph'])
      it 'should deploy ceph' do
        should contain_class('ceph').with(
          'fsid'                => fsid,
        )
      end

      it 'should configure glance pool' do
        should contain_ceph__pool(glance_pool).with(
          'pg_num'  => storage_hash['per_pool_pg_nums']['images'],
          'pgp_num' => storage_hash['per_pool_pg_nums']['images']
        )
      end 

      it 'should configure ceph glance key' do
        should contain_ceph__key("client.#{glance_user}").with(
          'secret'  => mon_key,
          'user'    => 'glance',
          'group'   => 'glance',
          'cap_mon' => 'allow r',
          'cap_osd' => "allow class-read object_prefix rbd_children, allow rwx pool=#{glance_pool}",
          'inject'  => true,
        )
      end
    
      it 'should configure cinder pool' do
        should contain_ceph__pool(cinder_pool).with(
          'pg_num'  => storage_hash['per_pool_pg_nums']['volumes'],
          'pgp_num' => storage_hash['per_pool_pg_nums']['volumes']
        )
      end

      it 'should configure ceph cinder key' do
        should contain_ceph__key("client.#{cinder_user}").with(
          'secret'  => mon_key,
          'user'    => 'cinder',
          'group'   => 'cinder',
          'cap_mon' => 'allow r',
          'cap_osd' => "allow class-read object_prefix rbd_children, allow rwx pool=#{cinder_pool}, allow rx pool=#{glance_pool}",
          'inject'  => true,
        )
      end

      it 'should configure cinder-backup pool' do
        should contain_ceph__pool(cinder_backup_pool).with(
          'pg_num'  => storage_hash['per_pool_pg_nums']['backups'],
          'pgp_num' => storage_hash['per_pool_pg_nums']['backups']
        )
      end

      it 'should configure ceph cinder-backup key' do
        should contain_ceph__key("client.#{cinder_backup_user}").with(
          'secret'  => mon_key,
          'user'    => 'cinder',
          'group'   => 'cinder',
          'cap_mon' => 'allow r',
          'cap_osd' => "allow class-read object_prefix rbd_children, allow rwx pool=#{cinder_backup_pool}, allow rwx pool=#{cinder_pool}",
          'inject'  => true,
        )
      end

      if storage_hash['volumes_ceph']
        it { should contain_ceph__pool("#{cinder_pool}").that_notifies('Service[cinder-volume]') }
        it { should contain_ceph__pool("#{cinder_backup_pool}").that_notifies('Service[cinder-backup]') }
        it { should contain_service('cinder-volume') }
        it { should contain_service('cinder-backup') }
      end

      if storage_hash['images_ceph']
        it { should contain_ceph__pool("#{glance_pool}").that_notifies('Service[glance-api]') }
        it { should contain_service('glance-api') }
      end
    end
  end
  test_ubuntu_and_centos manifest

end
