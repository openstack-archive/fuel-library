require 'spec_helper'

describe 'cinder::client' do

  let :params do
    {}
  end

  let :default_params do
    { :package_ensure   => 'present' }
  end

  shared_examples_for 'cinder client' do
    let :p do
      default_params.merge(params)
    end

    it { is_expected.to contain_class('cinder::params') }

    it 'installs cinder client package' do
      is_expected.to contain_package('python-cinderclient').with(
        :name   => 'python-cinderclient',
        :ensure => p[:package_ensure],
        :tag    => 'openstack'
      )
    end

  end

  context 'on Debian platform' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_configures 'cinder client'
  end

  context 'on RedHat platform' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_configures 'cinder client'
  end
end
