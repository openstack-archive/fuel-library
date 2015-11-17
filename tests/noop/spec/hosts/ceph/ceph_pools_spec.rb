require 'spec_helper'
require 'shared-examples'
manifest = 'ceph/ceph_pools.pp'

describe manifest do
  shared_examples 'catalog' do
    storage_hash = Noop.hiera 'storage'

    it { should contain_ceph__pool('images').with(
              'pg_num'        => storage_hash['pg_num'],
              'pgp_num'       => storage_hash['pg_num'],)
      }
    it { should contain_ceph__pool('volumes').with(
              'pg_num'        => storage_hash['pg_num'],
              'pgp_num'       => storage_hash['pg_num'],)
      }
    it { should contain_ceph__pool('backups').with(
              'pg_num'        => storage_hash['pg_num'],
              'pgp_num'       => storage_hash['pg_num'],)
      }

    if storage_hash['volumes_ceph']
      it { should contain_ceph__pool('volumes').that_notifies('Service[cinder-volume]') }
      it { should contain_ceph__pool('backups').that_notifies('Service[cinder-backup]') }
      it { should contain_service('cinder-volume') }
      it { should contain_service('cinder-backup') }
    end

    if storage_hash['images_ceph']
      it { should contain_ceph__pool('images').that_notifies('Service[glance-api]') }
      it { should contain_service('glance-api') }
    end

  end
  test_ubuntu_and_centos manifest

end
