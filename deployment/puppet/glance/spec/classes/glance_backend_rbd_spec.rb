require 'spec_helper'

describe 'glance::backend::rbd' do
  let :facts do
    {
      :osfamily => 'Debian'
    }
  end

  let :params do
    {
      :rbd_store_user  => 'glance',
    }
  end

  it { should contain_glance_api_config('DEFAULT/default_store').with_value('rbd') }
  it { should contain_glance_api_config('DEFAULT/rbd_store_pool').with_value('images') }
  it { should contain_glance_api_config('DEFAULT/rbd_store_ceph_conf').with_value('/etc/ceph/ceph.conf') }
  it { should contain_glance_api_config('DEFAULT/rbd_store_chunk_size').with_value('8') }

  it { should contain_package('python-ceph').with(
      :name   => 'python-ceph',
      :ensure => 'present'
    )
  }

  describe 'when passing params' do
    let :params do
      {
        :rbd_store_user       => 'user',
        :rbd_store_chunk_size => '2',
      }
      it { should contain_glance_api_config('DEFAULT/rbd_store_user').with_value('user') }
      it { should contain_glance_api_config('DEFAULT/rbd_store_chunk_size').with_value('2') }
    end
  end
end
