require 'spec_helper'
require 'shared-examples'
manifest = 'ceph/ceph_compute.pp'

describe manifest do
  shared_examples 'catalog' do
    storage_hash = Noop.hiera 'storage'

    if (storage_hash['images_ceph'] or storage_hash['objects_ceph'] or storage_hash['objects_ceph'])
      it { should contain_class('ceph').with(
           'osd_pool_default_size'    => storage_hash['osd_pool_size'],
           'osd_pool_default_pg_num'  => storage_hash['pg_num'],
           'osd_pool_default_pgp_num' => storage_hash['pg_num'],)
         }
      it { should contain_class('ceph::conf') }

      it { should contain_ceph__pool('compute').with(
          'pg_num'        => storage_hash['pg_num'],
          'pgp_num'       => storage_hash['pg_num'],)
        }

      it { should contain_ceph__pool('compute').that_requires('Class[ceph::conf]') }
      it { should contain_ceph__pool('compute').that_comes_before('Class[ceph::nova_compute]') }
      it { should contain_class('ceph::nova_compute').that_requires('Ceph::Pool[compute]') }
      it { should contain_class('ceph::nova_compute').that_requires('Service[libvirtd]')}

      if storage_hash['ephemeral_ceph']
        it { should contain_class('ceph::ephemeral') }
        it { should contain_class('ceph::conf').that_comes_before('Class[ceph::ephemeral]') }
      end
    end

  end
  test_ubuntu_and_centos manifest
end
