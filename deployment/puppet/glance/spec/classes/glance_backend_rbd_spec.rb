require 'spec_helper'

describe 'glance::backend::rbd' do
  let :facts do
    {
      :osfamily => 'Debian'
    }
  end

  describe 'when defaults with rbd_store_user' do
    let :params do
      {
        :rbd_store_user  => 'glance',
      }
    end

    it { is_expected.to contain_glance_api_config('glance_store/default_store').with_value('rbd') }
    it { is_expected.to contain_glance_api_config('glance_store/rbd_store_pool').with_value('images') }
    it { is_expected.to contain_glance_api_config('glance_store/rbd_store_ceph_conf').with_value('/etc/ceph/ceph.conf') }
    it { is_expected.to contain_glance_api_config('glance_store/rbd_store_chunk_size').with_value('8') }

    it { is_expected.to contain_package('python-ceph').with(
        :name   => 'python-ceph',
        :ensure => 'present'
      )
    }
  end

  describe 'when passing params' do
    let :params do
      {
        :rbd_store_user        => 'user',
        :rbd_store_chunk_size  => '2',
        :package_ensure        => 'latest',
      }
    end
    it { is_expected.to contain_glance_api_config('glance_store/rbd_store_user').with_value('user') }
    it { is_expected.to contain_glance_api_config('glance_store/rbd_store_chunk_size').with_value('2') }
    it { is_expected.to contain_package('python-ceph').with(
        :name   => 'python-ceph',
        :ensure => 'latest'
      )
    }
  end

  describe 'package on RedHat platform el6' do
    let :facts do
      {
        :osfamily               => 'RedHat',
        :operatingsystemrelease => '6.5',
      }
    end
    it { is_expected.to contain_package('python-ceph').with(
        :name   => 'python-ceph',
        :ensure => 'present'
      )
    }
  end
  describe 'package on RedHat platform el7' do
    let :facts do
      {
        :osfamily               => 'RedHat',
        :operatingsystemrelease => '7.0'
      }
    end
    it { is_expected.to contain_package('python-ceph').with(
        :name   => 'python-rbd',
        :ensure => 'present'
      )
    }
  end
end
