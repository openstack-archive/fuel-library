require 'spec_helper'

describe 'ceilometer::agent::compute' do

  let :pre_condition do
    "include nova\n" +
    "include nova::compute\n" +
    "class { 'ceilometer': metering_secret => 's3cr3t' }"
  end

  let :params do
    { :enabled        => true,
      :manage_service => true,
      :package_ensure => 'installed' }
  end

  shared_examples_for 'ceilometer-agent-compute' do

    it { is_expected.to contain_class('ceilometer::params') }

    it 'installs ceilometer-agent-compute package' do
      is_expected.to contain_package('ceilometer-agent-compute').with(
        :ensure => 'installed',
        :name   => platform_params[:agent_package_name],
        :before => ['Service[ceilometer-agent-compute]'],
        :tag    => 'openstack'
      )
    end

    it 'adds ceilometer user to nova group and, if required, to libvirt group' do
      if platform_params[:libvirt_group]
        is_expected.to contain_user('ceilometer').with_groups(['nova', "#{platform_params[:libvirt_group]}"])
      else
        is_expected.to contain_user('ceilometer').with_groups(['nova'])
      end
    end

    it 'ensures ceilometer-common is installed before the service' do
      is_expected.to contain_package('ceilometer-common').with(
        :before => /Service\[ceilometer-agent-compute\]/
      )
    end

    it 'ensures nova-common is installed before the package ceilometer-common' do
        is_expected.to contain_package('nova-common').with(
            :before => /Package\[ceilometer-common\]/
        )
    end

    it 'configures nova notification driver' do
      is_expected.to contain_file_line_after('nova-notification-driver-common').with(
        :line   => 'notification_driver=nova.openstack.common.notifier.rpc_notifier',
        :path   => '/etc/nova/nova.conf',
        :notify => 'Service[nova-compute]'
      )
      is_expected.to contain_file_line_after('nova-notification-driver-ceilometer').with(
        :line   => 'notification_driver=ceilometer.compute.nova_notifier',
        :path   => '/etc/nova/nova.conf',
        :notify => 'Service[nova-compute]'
      )
    end

    [{:enabled => true}, {:enabled => false}].each do |param_hash|
      context "when service should be #{param_hash[:enabled] ? 'enabled' : 'disabled'}" do
        before do
          params.merge!(param_hash)
        end

        it 'configures ceilometer-agent-compute service' do

          is_expected.to contain_service('ceilometer-agent-compute').with(
            :ensure     => (params[:manage_service] && params[:enabled]) ? 'running' : 'stopped',
            :name       => platform_params[:agent_service_name],
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

      it 'configures ceilometer-agent-compute service' do
        is_expected.to contain_service('ceilometer-agent-compute').with(
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
      { :agent_package_name => 'ceilometer-agent-compute',
        :agent_service_name => 'ceilometer-agent-compute' }
    end

    context 'on Ubuntu operating systems' do
      before do
        facts.merge!( :operatingsystem => 'Ubuntu' )
        platform_params.merge!( :libvirt_group => 'libvirtd' )
      end

      it_configures 'ceilometer-agent-compute'
    end

    context 'on other operating systems' do
      before do
        platform_params.merge!( :libvirt_group => 'libvirt' )
      end

      it_configures 'ceilometer-agent-compute'
    end
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :agent_package_name => 'openstack-ceilometer-compute',
        :agent_service_name => 'openstack-ceilometer-compute' }
    end

    it_configures 'ceilometer-agent-compute'
  end
end
