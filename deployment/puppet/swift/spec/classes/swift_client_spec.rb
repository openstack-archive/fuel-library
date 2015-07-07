require 'spec_helper'

describe 'swift::client' do

  let :params do
    {}
  end

  let :default_params do
    { :package_ensure   => 'present' }
  end

  shared_examples_for 'swift client' do
    let :p do
      default_params.merge(params)
    end

    it { is_expected.to contain_class('swift::params') }

    it 'installs swift client package' do
      is_expected.to contain_package('swiftclient').with(
        :name   => 'python-swiftclient',
        :ensure => p[:package_ensure],
        :tag    => 'openstack'
      )
    end

  end

  context 'on Debian platform' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_configures 'swift client'
  end

  context 'on RedHat platform' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_configures 'swift client'
  end
end
