require 'spec_helper'

describe 'neutron::agents::ml2::sriov' do

  let :pre_condition do
    "class { 'neutron': rabbit_password => 'passw0rd' }"
  end

  let :default_params do
    { :package_ensure             => 'present',
      :enabled                    => true,
      :physical_device_mappings   => [],
      :exclude_devices            => [],
      :polling_interval           => 2,
    }
  end

  let :default_facts do
    { :operatingsystem           => 'default',
      :operatingsystemrelease    => 'default'
    }
  end

  let :params do
    {}
  end

  shared_examples_for 'neutron sriov-nic agent with ml2 plugin' do
    let :p do
      default_params.merge(params)
    end

    it { is_expected.to contain_class('neutron::params') }

    it 'configures ovs_neutron_plugin.ini' do
      is_expected.to contain_neutron_plugin_ml2('sriov_nic/polling_interval').with_value(p[:polling_interval])
      is_expected.to contain_neutron_plugin_ml2('sriov_nic/exclude_devices').with_value(p[:exclude_devices].join(','))
      is_expected.to contain_neutron_plugin_ml2('sriov_nic/physical_device_mappings').with_value(p[:physical_device_mappings].join(','))
    end

    it 'installs neutron sriov-nic agent package' do
      is_expected.to contain_package('neutron-sriov-nic-agent').with(
        :name   => platform_params[:sriov_nic_agent_package],
        :ensure => p[:package_ensure],
        :tag    => 'openstack'
      )
      is_expected.to contain_package('neutron-sriov-nic-agent').with_before(/Neutron_plugin_ml2\[.+\]/)
    end

    it 'configures neutron ovs agent service' do
      is_expected.to contain_service('neutron-sriov-nic-agent-service').with(
        :name    => platform_params[:sriov_nic_agent_service],
        :enable  => true,
        :ensure  => 'running',
        :require => 'Class[Neutron]'
      )
    end

    context 'when supplying device mapping' do
      before :each do
        params.merge!(:physical_device_mappings => ['physnet1:eth1'],
                      :exclude_devices          => ['physnet1:eth2'])
      end

      it 'configures physical device mappings with exclusion' do
        is_expected.to contain_neutron_plugin_ml2('sriov_nic/exclude_devices').with_value(['physnet1:eth2'])
        is_expected.to contain_neutron_plugin_ml2('sriov_nic/physical_device_mappings').with_value(['physnet1:eth1'])
      end
    end
  end

  context 'on Debian platforms' do
    let :facts do
      default_facts.merge({ :osfamily => 'Debian' })
    end

    let :platform_params do
      { :sriov_nic_agent_package => 'neutron-plugin-sriov-agent',
        :sriov_nic_agent_service => 'neutron-plugin-sriov-agent' }
    end

    it_configures 'neutron sriov-nic agent with ml2 plugin'
  end

  context 'on RedHat platforms' do
    let :facts do
      default_facts.merge({ :osfamily => 'RedHat' })
    end

    let :platform_params do
      { :sriov_nic_agent_package => 'openstack-neutron-sriov-nic-agent',
        :sriov_nic_agent_service => 'neutron-sriov-nic-agent' }
    end

    it_configures 'neutron sriov-nic agent with ml2 plugin'
  end
end
