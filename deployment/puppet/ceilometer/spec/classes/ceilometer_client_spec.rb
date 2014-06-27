require 'spec_helper'

describe 'ceilometer::client' do

  shared_examples_for 'ceilometer client' do

    it { should contain_class('ceilometer::params') }

    it 'installs ceilometer client package' do
      should contain_package('python-ceilometerclient').with(
        :ensure => 'present',
        :name   => platform_params[:client_package_name]
      )
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      { :client_package_name => 'python-ceilometerclient' }
    end

    it_configures 'ceilometer client'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :client_package_name => 'python-ceilometerclient' }
    end

    it_configures 'ceilometer client'
  end
end
