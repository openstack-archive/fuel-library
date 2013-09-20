require 'spec_helper'

describe 'ceilometer::collector' do

  let :pre_condition do
    "class { 'ceilometer': metering_secret => 's3cr3t' }"
  end

  shared_examples_for 'ceilometer-collector' do

    it { should include_class('ceilometer::params') }

    it 'installs ceilometer-collector package' do
      should contain_package('ceilometer-collector').with(
        :ensure => 'installed',
        :name   => platform_params[:collector_package_name]
      )
    end

    it 'configures ceilometer-collector service' do
      should contain_service('ceilometer-collector').with(
        :ensure     => 'running',
        :name       => platform_params[:collector_service_name],
        :enable     => true,
        :hasstatus  => true,
        :hasrestart => true,
        :require    => 'Class[Ceilometer::Db]',
        :subscribe  => 'Exec[ceilometer-dbsync]'
      )
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      { :collector_package_name => 'ceilometer-collector',
        :collector_service_name => 'ceilometer-collector' }
    end

    it_configures 'ceilometer-collector'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :collector_package_name => 'openstack-ceilometer-collector',
        :collector_service_name => 'openstack-ceilometer-collector' }
    end

    it_configures 'ceilometer-collector'
  end
end
