require 'spec_helper'

describe 'heat::client' do

  let :params do
    {}
  end

  let :default_params do
    { :package_ensure   => 'present' }
  end

  shared_examples_for 'heat client' do
    let :p do
      default_params.merge(params)
    end

    it { is_expected.to contain_class('heat::params') }

    it 'installs heat client package' do
      is_expected.to contain_package('python-heatclient').with(
        :name   => 'python-heatclient',
        :ensure => p[:package_ensure],
        :tag    => 'openstack'
      )
    end

  end

  context 'on Debian platform' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_configures 'heat client'
  end

  context 'on RedHat platform' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_configures 'heat client'
  end
end
