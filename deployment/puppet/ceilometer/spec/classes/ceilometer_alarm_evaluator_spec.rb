require 'spec_helper'

describe 'ceilometer::alarm::evaluator' do

  let :pre_condition do
    "class { 'ceilometer': metering_secret => 's3cr3t' }"
  end

  let :params do
    { :evaluation_interval   => 60,
      :evaluation_service    => 'ceilometer.alarm.service.SingletonAlarmService',
      :partition_rpc_topic   => 'alarm_partition_coordination',
      :record_history        => true,
      :enabled               => true,
      :manage_service        => true,
    }
  end

  shared_examples_for 'ceilometer-alarm-evaluator' do
    it { is_expected.to contain_class('ceilometer::params') }

    it 'installs ceilometer-alarm package' do
      is_expected.to contain_package(platform_params[:alarm_evaluator_package_name]).with_before(['Service[ceilometer-alarm-evaluator]'])
      is_expected.to contain_package(platform_params[:alarm_evaluator_package_name]).with(
        :ensure => 'present',
        :name   => platform_params[:alarm_evaluator_package_name],
        :tag    => 'openstack'
      )
    end

    it 'ensures ceilometer-common is installed before the service' do
      is_expected.to contain_package('ceilometer-common').with(
        :before => /Service\[ceilometer-alarm-evaluator\]/
      )
    end

    it 'configures alarm evaluator' do
      is_expected.to contain_ceilometer_config('alarm/evaluation_interval').with_value( params[:evaluation_interval] )
      is_expected.to contain_ceilometer_config('alarm/evaluation_service').with_value( params[:evaluation_service] )
      is_expected.to contain_ceilometer_config('alarm/partition_rpc_topic').with_value( params[:partition_rpc_topic] )
      is_expected.to contain_ceilometer_config('alarm/record_history').with_value( params[:record_history] )
      is_expected.to_not contain_ceilometer_config('coordination/backend_url')
    end

    context 'when overriding parameters' do
      before do
        params.merge!(:evaluation_interval => 80,
                      :partition_rpc_topic => 'alarm_partition_coordination',
                      :record_history      => false,
                      :evaluation_service  => 'ceilometer.alarm.service.SingletonTestAlarmService',
                      :coordination_url     => 'redis://localhost:6379')
      end
      it { is_expected.to contain_ceilometer_config('alarm/evaluation_interval').with_value(params[:evaluation_interval]) }
      it { is_expected.to contain_ceilometer_config('alarm/evaluation_service').with_value(params[:evaluation_service]) }
      it { is_expected.to contain_ceilometer_config('alarm/record_history').with_value(params[:record_history]) }
      it { is_expected.to contain_ceilometer_config('alarm/partition_rpc_topic').with_value(params[:partition_rpc_topic])  }
      it { is_expected.to contain_ceilometer_config('coordination/backend_url').with_value( params[:coordination_url]) }
    end

    context 'when override the evaluation interval with a non numeric value' do
      before do
        params.merge!(:evaluation_interval => 'NaN')
      end

      it { expect { is_expected.to contain_ceilometer_config('alarm/evaluation_interval') }.to\
        raise_error(Puppet::Error, /validate_re\(\): .* does not match/) }
    end

    [{:enabled => true}, {:enabled => false}].each do |param_hash|
      context "when service should be #{param_hash[:enabled] ? 'enabled' : 'disabled'}" do
        before do
          params.merge!(param_hash)
        end

        it 'configures ceilometer-alarm-evaluator service' do
          is_expected.to contain_service('ceilometer-alarm-evaluator').with(
            :ensure     => (params[:manage_service] && params[:enabled]) ? 'running' : 'stopped',
            :name       => platform_params[:alarm_evaluator_service_name],
            :enable     => params[:enabled],
            :hasstatus  => true,
            :hasrestart => true
          )
        end
      end
    end

    context 'with disabled service managing' do
      before do
        params.merge!({
          :manage_service => false,
          :enabled        => false })
      end

      it 'configures ceilometer-alarm-evaluator service' do
        is_expected.to contain_service('ceilometer-alarm-evaluator').with(
          :ensure     => nil,
          :name       => platform_params[:alarm_evaluator_service_name],
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
      { :alarm_evaluator_package_name => 'ceilometer-alarm-evaluator',
        :alarm_evaluator_service_name => 'ceilometer-alarm-evaluator' }
    end

    it_configures 'ceilometer-alarm-evaluator'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :alarm_evaluator_package_name => 'openstack-ceilometer-alarm',
        :alarm_evaluator_service_name => 'openstack-ceilometer-alarm-evaluator' }
    end

    it_configures 'ceilometer-alarm-evaluator'
  end

end
