require 'spec_helper'

describe 'ceilometer::agent::central' do

  let :pre_condition do
    "class { 'ceilometer': metering_secret => 's3cr3t' }"
  end

  let :params do
    { :enabled          => true,
      :manage_service   => true,
      :package_ensure   => 'latest',
      :coordination_url => 'redis://localhost:6379'
    }
  end

  shared_examples_for 'ceilometer-agent-central' do

    it { is_expected.to contain_class('ceilometer::params') }

    it 'installs ceilometer-agent-central package' do
      is_expected.to contain_package('ceilometer-agent-central').with(
        :ensure => 'latest',
        :name   => platform_params[:agent_package_name],
        :before => ['Service[ceilometer-agent-central]'],
        :tag    => 'openstack'
      )
    end

    it 'ensures ceilometer-common is installed before the service' do
      is_expected.to contain_package('ceilometer-common').with(
        :before => /Service\[ceilometer-agent-central\]/
      )
    end

    [{:enabled => true}, {:enabled => false}].each do |param_hash|
      context "when service should be #{param_hash[:enabled] ? 'enabled' : 'disabled'}" do
        before do
          params.merge!(param_hash)
        end

        it 'configures ceilometer-agent-central service' do
          is_expected.to contain_service('ceilometer-agent-central').with(
            :ensure     => (params[:manage_service] && params[:enabled]) ? 'running' : 'stopped',
            :name       => platform_params[:agent_service_name],
            :enable     => params[:enabled],
            :hasstatus  => true,
            :hasrestart => true
          )
        end
      end
    end

    it 'configures central agent' do
      is_expected.to contain_ceilometer_config('coordination/backend_url').with_value( params[:coordination_url] )
    end

    context 'with disabled service managing' do
      before do
        params.merge!({
          :manage_service => false,
          :enabled        => false })
      end

      it 'configures ceilometer-agent-central service' do
        is_expected.to contain_service('ceilometer-agent-central').with(
          :ensure     => nil,
          :name       => platform_params[:agent_service_name],
          :enable     => false,
          :hasstatus  => true,
          :hasrestart => true
        )
      end
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
