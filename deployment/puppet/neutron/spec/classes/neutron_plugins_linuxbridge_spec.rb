require 'spec_helper'

describe 'neutron::plugins::linuxbridge' do

  let :pre_condition do
    "class { 'neutron': rabbit_password => 'passw0rd' }"
  end

  let :params do
    { :sql_connection      => false,
      :network_vlan_ranges => 'physnet0:100:109',
      :tenant_network_type => 'vlan',
      :package_ensure      => 'installed'
    }
  end

  shared_examples_for 'neutron linuxbridge plugin' do

    it { should contain_class('neutron::params') }

    it 'installs neutron linuxbridge plugin package' do
      should contain_package('neutron-plugin-linuxbridge').with(
        :ensure => params[:package_ensure],
        :name   => platform_params[:linuxbridge_plugin_package]
      )
    end

    it 'configures linuxbridge_conf.ini' do
      should contain_neutron_plugin_linuxbridge('VLANS/tenant_network_type').with(
        :value => params[:tenant_network_type]
      )
      should contain_neutron_plugin_linuxbridge('VLANS/network_vlan_ranges').with(
        :value => params[:network_vlan_ranges]
      )
    end

    it 'should create plugin symbolic link' do
      should contain_file('/etc/neutron/plugin.ini').with(
        :ensure  => 'link',
        :target  => '/etc/neutron/plugins/linuxbridge/linuxbridge_conf.ini',
        :require => 'Package[neutron-plugin-linuxbridge]'
      )
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      { :linuxbridge_plugin_package => 'neutron-plugin-linuxbridge' }
    end

    context 'on Ubuntu operating systems' do
      before do
        facts.merge!({:operatingsystem => 'Ubuntu'})
      end

      it 'configures /etc/default/neutron-server' do
        should contain_file_line('/etc/default/neutron-server:NEUTRON_PLUGIN_CONFIG').with(
          :path    => '/etc/default/neutron-server',
          :match   => '^NEUTRON_PLUGIN_CONFIG=(.*)$',
          :line    => 'NEUTRON_PLUGIN_CONFIG=/etc/neutron/plugins/linuxbridge/linuxbridge_conf.ini',
          :require => ['Package[neutron-plugin-linuxbridge]', 'Package[neutron-server]'],
          :notify  => 'Service[neutron-server]'
        )
      end
      it_configures 'neutron linuxbridge plugin'
    end

    context 'on Debian operating systems' do
      before do
        facts.merge!({:operatingsystem => 'Debian'})
      end

      it_configures 'neutron linuxbridge plugin'
    end
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :linuxbridge_plugin_package => 'openstack-neutron-linuxbridge' }
    end

    it_configures 'neutron linuxbridge plugin'
  end
end
