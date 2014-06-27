require 'spec_helper'

describe 'ceilometer::alarm::notifier' do

  let :pre_condition do
    "class { 'ceilometer': metering_secret => 's3cr3t' }"
  end

  let :params do
    {
      #:notifier_rpc_topic              => 'UNSET',
      #:rest_notifier_certificate_key   => 'UNSET',
      #:rest_notifier_certificate_file  => 'UNSET',
      #:rest_notifier_ssl_verify        => true,
      :enabled                         => true,
    }
  end

  shared_examples_for 'ceilometer-alarm-notifier' do
    it { should contain_class('ceilometer::params') }

    it 'installs ceilometer-alarm package' do
      should contain_package(platform_params[:alarm_notifier_package_name]).with_before('Service[ceilometer-alarm-notifier]')
      should contain_package(platform_params[:alarm_notifier_package_name]).with(
        :ensure => 'present',
        :name   => platform_params[:alarm_notifier_package_name]
      )
    end

    it 'ensures ceilometer-common is installed before the service' do
      should contain_package('ceilometer-common').with(
        :before => /Service\[ceilometer-alarm-notifier\]/
      )
    end

    it 'configures ceilometer-alarm-notifier service' do
      should contain_service('ceilometer-alarm-notifier').with(
        :ensure     => 'running',
        :name       => platform_params[:alarm_notifier_service_name],
        :enable     => true,
        :hasstatus  => true,
        :hasrestart => true
      )
    end


    it 'configures alarm notifier' do
      should_not contain_ceilometer_config('alarm/notifier_rpc_topic')
      should_not contain_ceilometer_config('alarm/rest_notifier_certificate_key')
      should_not contain_ceilometer_config('alarm/rest_notifier_certificate_file')
      should_not contain_ceilometer_config('alarm/rest_notifier_ssl_verify')
    end

    context 'when overriding parameters' do
      before do
        params.merge!(:notifier_rpc_topic             => 'alarm_notifier',
                      :rest_notifier_certificate_key  => '0xdeadbeef',
                      :rest_notifier_certificate_file => '/var/file',
                      :rest_notifier_ssl_verify       => true)
      end
      it { should contain_ceilometer_config('alarm/notifier_rpc_topic').with_value(params[:notifier_rpc_topic]) }
      it { should contain_ceilometer_config('alarm/rest_notifier_certificate_key').with_value(params[:rest_notifier_certificate_key]) }
      it { should contain_ceilometer_config('alarm/rest_notifier_certificate_file').with_value(params[:rest_notifier_certificate_file]) }
      it { should contain_ceilometer_config('alarm/rest_notifier_ssl_verify').with_value(params[:rest_notifier_ssl_verify])  }
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      { :alarm_notifier_package_name => 'ceilometer-alarm-notifier',
        :alarm_notifier_service_name => 'ceilometer-alarm-notifier' }
    end

    it_configures 'ceilometer-alarm-notifier'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :alarm_notifier_package_name => 'openstack-ceilometer-alarm',
        :alarm_notifier_service_name => 'openstack-ceilometer-alarm-notifier' }
    end

    it_configures 'ceilometer-alarm-notifier'
  end

end
