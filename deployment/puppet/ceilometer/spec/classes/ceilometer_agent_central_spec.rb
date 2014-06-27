require 'spec_helper'

describe 'ceilometer::agent::central' do

  let :pre_condition do
    "class { 'ceilometer': metering_secret => 's3cr3t' }"
  end

  let :params do
    { :enabled          => true }
  end

  shared_examples_for 'ceilometer-agent-central' do

    it { should contain_class('ceilometer::params') }

    it 'installs ceilometer-agent-central package' do
      should contain_package('ceilometer-agent-central').with(
        :ensure => 'installed',
        :name   => platform_params[:agent_package_name],
        :before => 'Service[ceilometer-agent-central]'
      )
    end

    it 'ensures ceilometer-common is installed before the service' do
      should contain_package('ceilometer-common').with(
        :before => /Service\[ceilometer-agent-central\]/
      )
    end

    it 'configures ceilometer-agent-central service' do
      should contain_service('ceilometer-agent-central').with(
        :ensure     => 'running',
        :name       => platform_params[:agent_service_name],
        :enable     => true,
        :hasstatus  => true,
        :hasrestart => true
      )
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      { :agent_package_name => 'ceilometer-agent-central',
        :agent_service_name => 'ceilometer-agent-central' }
    end

    it_configures 'ceilometer-agent-central'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :agent_package_name => 'openstack-ceilometer-central',
        :agent_service_name => 'openstack-ceilometer-central' }
    end

    it_configures 'ceilometer-agent-central'
  end
end
