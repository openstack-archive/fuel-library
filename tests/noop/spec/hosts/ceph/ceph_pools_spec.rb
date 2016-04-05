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
manifest = 'ceph/ceph_pools.pp'

describe manifest do
  shared_examples 'catalog' do
    storage_hash       = Noop.hiera_hash 'storage'
    glance_pool        = 'images'
    cinder_pool        = 'volumes'
    cinder_backup_pool = 'backups'


    if (storage_hash['images_ceph'] or storage_hash['objects_ceph'])
      it { should contain_ceph__pool("#{glance_pool}").with(
              'acl'     => "mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=#{glance_pool}'",
              'pg_num'  => storage_hash['per_pool_pg_nums']['images'],
              'pgp_num' => storage_hash['per_pool_pg_nums']['images'],)
        }
      it { should contain_ceph__pool("#{cinder_pool}").with(
              'acl'     => "mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=#{cinder_pool}, allow rx pool=#{glance_pool}'",
              'pg_num'  => storage_hash['per_pool_pg_nums']['volumes'],
              'pgp_num' => storage_hash['per_pool_pg_nums']['volumes'],)
        }
      it { should contain_ceph__pool("#{cinder_backup_pool}").with(
              'acl'     => "mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=#{cinder_backup_pool}, allow rwx pool=#{cinder_pool}'",
              'pg_num'  => storage_hash['per_pool_pg_nums']['backups'],
              'pgp_num' => storage_hash['per_pool_pg_nums']['backups'],)
        }

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
