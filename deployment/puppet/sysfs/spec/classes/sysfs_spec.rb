require 'spec_helper'

describe 'sysfs' do

  let(:default_params) { {
  } }

  shared_examples_for 'sysfs configuration' do
    let :params do
      default_params
    end

    context 'with default params' do
      let :params do
        default_params.merge({})
      end

      it 'configures with the default params' do
        should contain_class('sysfs')
        should contain_class('sysfs::install')
        should contain_class('sysfs::service')
      end
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian',
        :operatingsystem => 'Debian',
        :hostname => 'hostname.example.com', }
    end

    it_configures 'sysfs configuration'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
        :hostname => 'hostname.example.com', }
    end

    it_configures 'sysfs configuration'
  end

end

