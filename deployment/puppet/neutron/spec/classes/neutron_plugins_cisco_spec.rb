require 'spec_helper'

describe 'neutron::plugins::cisco' do

  let :pre_condition do
    "class { 'neutron::server': auth_password => 'password'}
     class { 'neutron': rabbit_password => 'passw0rd' }"
  end

  let :params do
    { :keystone_username => 'neutron',
      :keystone_password => 'neutron_pass',
      :keystone_auth_url => 'http://127.0.0.1:35357/v2.0/',
      :keystone_tenant   => 'tenant',

      :database_name     => 'neutron',
      :database_pass     => 'dbpass',
      :database_host     => 'localhost',
      :database_user     => 'neutron'}
  end

  let :params_default do
    {
      :vswitch_plugin    => 'neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2',
      :vlan_start        => '100',
      :vlan_end          => '3000',
      :vlan_name_prefix  => 'q-',
      :model_class       => 'neutron.plugins.cisco.models.virt_phy_sw_v2.VirtualPhysicalSwitchModelV2',
      :max_ports         => '100',
      :max_port_profiles => '65568',
      :max_networks      => '65568',
      :manager_class     => 'neutron.plugins.cisco.segmentation.l2network_vlan_mgr_v2.L2NetworkVLANMgr'
    }
  end

  let :default_facts do
    { :operatingsystem           => 'default',
      :operatingsystemrelease    => 'default'
    }
  end

  shared_examples_for 'default cisco plugin' do

    before do
      params.merge!(params_default)
    end

    it 'should create plugin symbolic link' do
      is_expected.to contain_file('/etc/neutron/plugin.ini').with(
        :ensure  => 'link',
        :target  => '/etc/neutron/plugins/cisco/cisco_plugins.ini',
        :require => 'Package[neutron-plugin-cisco]'
      )
    end

    it 'should have a plugin config folder' do
      is_expected.to contain_file('/etc/neutron/plugins').with(
        :ensure => 'directory',
        :owner  => 'root',
        :group  => 'neutron',
        :mode   => '0640'
      )
    end

    it 'should have a cisco plugin config folder' do
      is_expected.to contain_file('/etc/neutron/plugins/cisco').with(
        :ensure => 'directory',
        :owner  => 'root',
        :group  => 'neutron',
        :mode   => '0640'
      )
    end

    it 'should perform default l2 configuration' do
      is_expected.to contain_neutron_plugin_cisco_l2network('VLANS/vlan_start').\
        with_value(params[:vlan_start])
      is_expected.to contain_neutron_plugin_cisco_l2network('VLANS/vlan_end').\
        with_value(params[:vlan_end])
      is_expected.to contain_neutron_plugin_cisco_l2network('VLANS/vlan_name_prefix').\
        with_value(params[:vlan_name_prefix])
      is_expected.to contain_neutron_plugin_cisco_l2network('MODEL/model_class').\
        with_value(params[:model_class])
      is_expected.to contain_neutron_plugin_cisco_l2network('PORTS/max_ports').\
        with_value(params[:max_ports])
      is_expected.to contain_neutron_plugin_cisco_l2network('PORTPROFILES/max_port_profiles').\
        with_value(params[:max_port_profiles])
      is_expected.to contain_neutron_plugin_cisco_l2network('NETWORKS/max_networks').\
        with_value(params[:max_networks])
      is_expected.to contain_neutron_plugin_cisco_l2network('SEGMENTATION/manager_class').\
        with_value(params[:manager_class])
    end

    it 'should create a dummy inventory item' do
      is_expected.to contain_neutron_plugin_cisco('INVENTORY/dummy').\
        with_value('dummy')
    end

    it 'should configure the db connection' do
      is_expected.to contain_neutron_plugin_cisco_db_conn('DATABASE/name').\
        with_value(params[:database_name])
      is_expected.to contain_neutron_plugin_cisco_db_conn('DATABASE/user').\
        with_value(params[:database_user])
      is_expected.to contain_neutron_plugin_cisco_db_conn('DATABASE/pass').\
        with_value(params[:database_pass])
      is_expected.to contain_neutron_plugin_cisco_db_conn('DATABASE/host').\
        with_value(params[:database_host])
    end

    it 'should configure the admin credentials' do
      is_expected.to contain_neutron_plugin_cisco_credentials('keystone/username').\
        with_value(params[:keystone_username])
      is_expected.to contain_neutron_plugin_cisco_credentials('keystone/password').\
        with_value(params[:keystone_password])
      is_expected.to contain_neutron_plugin_cisco_credentials('keystone/password').with_secret( true )
      is_expected.to contain_neutron_plugin_cisco_credentials('keystone/auth_url').\
        with_value(params[:keystone_auth_url])
      is_expected.to contain_neutron_plugin_cisco_credentials('keystone/tenant').\
        with_value(params[:keystone_tenant])
    end

    it 'should perform vswitch plugin configuration' do
      is_expected.to contain_neutron_plugin_cisco('PLUGINS/vswitch_plugin').\
          with_value('neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2')
    end

    describe 'with nexus plugin' do
      before do
        params.merge!(:nexus_plugin => 'neutron.plugins.cisco.nexus.cisco_nexus_plugin_v2.NexusPlugin')
      end

      it 'should perform nexus plugin configuration' do
        is_expected.to contain_neutron_plugin_cisco('PLUGINS/nexus_plugin').\
          with_value('neutron.plugins.cisco.nexus.cisco_nexus_plugin_v2.NexusPlugin')
      end
    end

  end
  context 'on Debian platforms' do
    let :facts do
      default_facts.merge({ :osfamily => 'Debian' })
    end

    context 'on Ubuntu operating systems' do
      before do
        facts.merge!({:operatingsystem => 'Ubuntu'})
      end

      it 'configures /etc/default/neutron-server' do
        is_expected.to contain_file_line('/etc/default/neutron-server:NEUTRON_PLUGIN_CONFIG').with(
          :path    => '/etc/default/neutron-server',
          :match   => '^NEUTRON_PLUGIN_CONFIG=(.*)$',
          :line    => 'NEUTRON_PLUGIN_CONFIG=/etc/neutron/plugins/cisco/cisco_plugins.ini',
          :require => ['Package[neutron-server]', 'Package[neutron-plugin-cisco]'],
          :notify  => 'Service[neutron-server]'
        )
      end
      it_configures 'default cisco plugin'
    end

    context 'on Debian operating systems' do
      before do
        facts.merge!({:operatingsystem => 'Debian'})
      end

      it_configures 'default cisco plugin'
    end
  end

  context 'on RedHat platforms' do
    let :facts do
      default_facts.merge({ :osfamily => 'RedHat' })
    end

    it_configures 'default cisco plugin'

  end

end
