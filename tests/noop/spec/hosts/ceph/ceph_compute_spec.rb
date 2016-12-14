# ROLE: compute

require 'spec_helper'
require 'shared-examples'
manifest = 'ceph/ceph_compute.pp'

describe manifest do
  shared_examples 'catalog' do
    storage_hash = Noop.hiera_hash 'storage'
    glance_pool  = 'images'
    cinder_pool  = 'volumes'
    compute_pool = 'compute'

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
      it { should contain_class('ceph').with(
           'osd_pool_default_size'    => storage_hash['osd_pool_size'],
           'osd_pool_default_pg_num'  => storage_hash['pg_num'],
           'osd_pool_default_pgp_num' => storage_hash['pg_num'],)
         }
      it { should contain_class('ceph::conf') }

      it { should contain_ceph__pool('compute').with(
          'acl'     => "mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=#{cinder_pool}, allow rwx pool=#{glance_pool}, allow rwx pool=#{compute_pool}'",
          'pg_num'  => storage_hash['per_pool_pg_nums']['compute'],
          'pgp_num' => storage_hash['per_pool_pg_nums']['compute'],)
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
    end
  end
  test_ubuntu_and_centos manifest
end
