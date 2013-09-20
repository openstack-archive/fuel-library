require 'spec_helper'

describe 'ceilometer::agent::compute' do

  let :pre_condition do
    "include nova\n" +
    "include nova::compute\n" +
    "class { 'ceilometer': metering_secret => 's3cr3t' }"
  end

  let :params do
    { :auth_url         => 'http://localhost:5000/v2.0',
      :auth_region      => 'RegionOne',
      :auth_user        => 'ceilometer',
      :auth_password    => 'password',
      :auth_tenant_name => 'services',
      :enabled          => true,
    }
  end

  shared_examples_for 'ceilometer-agent-compute' do

    it { should include_class('ceilometer::params') }

    it 'installs ceilometer-agent-compute package' do
      should contain_package('ceilometer-agent-compute').with(
        :ensure => 'installed',
        :name   => platform_params[:agent_package_name],
        :before => 'Service[ceilometer-agent-compute]'
      )
    end

    it 'adds ceilometer user to libvirt group if required' do
      if platform_params[:libvirt_group]
        should contain_user('ceilometer').with_groups(/#{platform_params[:libvirt_group]}/)
      end
    end

    it 'ensures ceilometer-common is installed before the service' do
      should contain_package('ceilometer-common').with(
        :before => /Service\[ceilometer-agent-compute\]/
      )
    end

    it 'configures ceilometer-agent-compute service' do
      should contain_service('ceilometer-agent-compute').with(
        :ensure     => 'running',
        :name       => platform_params[:agent_service_name],
        :enable     => true,
        :hasstatus  => true,
        :hasrestart => true
      )
    end

    it 'configures authentication' do
      should contain_ceilometer_config('DEFAULT/os_auth_url').with_value('http://localhost:5000/v2.0')
      should contain_ceilometer_config('DEFAULT/os_auth_region').with_value('RegionOne')
      should contain_ceilometer_config('DEFAULT/os_username').with_value('ceilometer')
      should contain_ceilometer_config('DEFAULT/os_password').with_value('password')
      should contain_ceilometer_config('DEFAULT/os_tenant_name').with_value('services')
    end

    it 'configures instance usage audit in nova' do
      should contain_nova_config('DEFAULT/instance_usage_audit').with_value('True')
      should contain_nova_config('DEFAULT/instance_usage_audit_period').with_value('hour')
    end

    it 'configures nova notification driver' do
      should contain_file_line('nova-notification-driver-common').with(
        :line   => 'notification_driver=nova.openstack.common.notifier.rpc_notifier',
        :path   => '/etc/nova/nova.conf',
        :notify => 'Service[nova-compute]'
      )
      should contain_file_line('nova-notification-driver-ceilometer').with(
        :line   => 'notification_driver=ceilometer.compute.nova_notifier',
        :path   => '/etc/nova/nova.conf',
        :notify => 'Service[nova-compute]'
      )
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
