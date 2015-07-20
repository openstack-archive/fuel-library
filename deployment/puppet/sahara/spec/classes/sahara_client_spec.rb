#
# Unit tests for sahara::client
#
require 'spec_helper'

describe 'sahara::client' do

  shared_examples_for 'sahara client' do

    context 'with default parameters' do
      it { is_expected.to contain_package('python-saharaclient').with(
        :ensure => 'present',
        :tag    => 'openstack',
        )
      }
    end

    context 'with package_ensure parameter provided' do
      let :params do
        { :package_ensure => false }
      end
      it { is_expected.to contain_package('python-saharaclient').with(
        :ensure => false,
        :tag    => 'openstack',
        )
      }
    end

  end

  context 'on Debian platforms' do
    let :facts do
      {
        :osfamily => 'Debian',
        :operatingsystem => 'Debian'
      }
    end

    it_configures 'sahara client'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_configures 'sahara client'
  end
end
