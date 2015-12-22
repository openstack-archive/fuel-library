require 'spec_helper'

describe 'sysfs::install' do

  let(:default_params) { {
  } }

  shared_examples_for 'sysfs::install configuration' do
    let :params do
      default_params
    end

    context 'with default params' do
      let :params do
        default_params.merge({})
      end

      it 'configures with the default params' do
        should contain_class('sysfs::install')
        should contain_class('sysfs::params')
        should contain_package('sysfsutils').with(
          :ensure => 'installed',
          :name   => 'sysfsutils')
        if facts[:osfamily] == 'RedHat'
          should contain_file('sysfsutils.init').with(
            :ensure => 'present',
            :source => 'puppet:///modules/sysfs/centos-sysfsutils.init.sh')
        end
      end
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian',
        :operatingsystem => 'Debian',
        :hostname => 'hostname.example.com', }
    end

    it_configures 'sysfs::install configuration'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
        :hostname => 'hostname.example.com', }
    end

    it_configures 'sysfs::install configuration'
  end

end

