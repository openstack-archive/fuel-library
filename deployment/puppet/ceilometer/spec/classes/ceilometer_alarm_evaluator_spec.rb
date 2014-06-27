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
    }
  end

  shared_examples_for 'ceilometer-alarm-evaluator' do
    it { should contain_class('ceilometer::params') }

    it 'installs ceilometer-alarm package' do
      should contain_package(platform_params[:alarm_evaluator_package_name]).with_before('Service[ceilometer-alarm-evaluator]')
      should contain_package(platform_params[:alarm_evaluator_package_name]).with(
        :ensure => 'present',
        :name   => platform_params[:alarm_evaluator_package_name]
      )
    end

    it 'ensures ceilometer-common is installed before the service' do
      should contain_package('ceilometer-common').with(
        :before => /Service\[ceilometer-alarm-evaluator\]/
      )
    end

    it 'configures ceilometer-alarm-evaluator service' do
      should contain_service('ceilometer-alarm-evaluator').with(
        :ensure     => 'running',
        :name       => platform_params[:alarm_evaluator_service_name],
        :enable     => true,
        :hasstatus  => true,
        :hasrestart => true
      )
    end


    it 'configures alarm evaluator' do
      should contain_ceilometer_config('alarm/evaluation_interval').with_value( params[:evaluation_interval] )
      should contain_ceilometer_config('alarm/evaluation_service').with_value( params[:evaluation_service] )
      should contain_ceilometer_config('alarm/partition_rpc_topic').with_value( params[:partition_rpc_topic] )
      should contain_ceilometer_config('alarm/record_history').with_value( params[:record_history] )
    end

    context 'when overriding parameters' do
      before do
        params.merge!(:evaluation_interval => 80,
                      :partition_rpc_topic => 'alarm_partition_coordination',
                      :record_history      => false,
                      :evaluation_service  => 'ceilometer.alarm.service.SingletonTestAlarmService')
      end
      it { should contain_ceilometer_config('alarm/evaluation_interval').with_value(params[:evaluation_interval]) }
      it { should contain_ceilometer_config('alarm/evaluation_service').with_value(params[:evaluation_service]) }
      it { should contain_ceilometer_config('alarm/record_history').with_value(params[:record_history]) }
      it { should contain_ceilometer_config('alarm/partition_rpc_topic').with_value(params[:partition_rpc_topic])  }
    end

      context 'when override the evaluation interval with a non numeric value' do
        before do
          params.merge!(:evaluation_interval => 'NaN')
        end

        it { expect { should contain_ceilometer_config('alarm/evaluation_interval') }.to\
          raise_error(Puppet::Error, /validate_re\(\): .* does not match/) }
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
