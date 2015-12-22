require 'spec_helper'

describe 'sysfs::service' do

  let(:default_params) { {
  } }

  shared_examples_for 'sysfs::service configuration' do
    let :params do
      default_params
    end

    context 'with default params' do
      let :params do
        default_params.merge({})
      end

      it 'configures with the default params' do
        should contain_class('sysfs::service')
        should contain_service('sysfsutils').with(
          :ensure     => 'running',
          :enable     => true,
          :hasstatus  => false,
          :hasrestart => true)
        should contain_tweaks__ubuntu_service_override('sysfsutils').with(
          :package_name => 'sysfsutils')
      end
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian',
        :operatingsystem => 'Debian',
        :hostname => 'hostname.example.com', }
    end

    it_configures 'sysfs::service configuration'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
        :hostname => 'hostname.example.com', }
    end

    it_configures 'sysfs::service configuration'
  end

end

