require 'spec_helper'

describe 'neutron::agents::ml2::linuxbridge' do

  let :pre_condition do
    "class { 'neutron': rabbit_password => 'passw0rd' }"
  end

  let :default_params do
    { :package_ensure   => 'present',
      :enabled          => true,
      :tunnel_types     => [],
      :local_ip         => false,
      :vxlan_group      => '224.0.0.1',
      :vxlan_ttl        => false,
      :vxlan_tos        => false,
      :polling_interval => 2,
      :l2_population    => false,
      :physical_interface_mappings => [],
      :firewall_driver  => 'neutron.agent.linux.iptables_firewall.IptablesFirewallDriver' }
  end

  let :default_facts do
    { :operatingsystem           => 'default',
      :operatingsystemrelease    => 'default'
    }
  end

  let :params do
    {}
  end

  shared_examples_for 'neutron plugin linuxbridge agent with ml2 plugin' do

    context 'with default parameters' do
      it { is_expected.to contain_class('neutron::params') }

      it 'configures ml2_conf.ini' do
        is_expected.to contain_neutron_agent_linuxbridge('agent/polling_interval').with_value(default_params[:polling_interval])
        is_expected.to contain_neutron_agent_linuxbridge('linux_bridge/physical_interface_mappings').with_value(default_params[:physical_interface_mappings].join(','))
        is_expected.to contain_neutron_agent_linuxbridge('securitygroup/firewall_driver').with_value(default_params[:firewall_driver])
      end

      it 'installs neutron linuxbridge agent package' do
        if platform_params.has_key?(:linuxbridge_agent_package)
          linuxbridge_agent_package = platform_params[:linuxbridge_agent_package]
        else
          linuxbridge_agent_package = platform_params[:linuxbridge_server_package]
        end

        is_expected.to contain_package('neutron-plugin-linuxbridge-agent').with(
          :name   => linuxbridge_agent_package,
          :ensure => default_params[:package_ensure],
          :tag    => 'openstack'
        )

        is_expected.to contain_package('neutron-plugin-linuxbridge-agent').with_before(/Neutron_agent_linuxbridge\[.+\]/)
      end

      it 'configures neutron linuxbridge agent service' do
        is_expected.to contain_service('neutron-plugin-linuxbridge-agent').with(
          :name    => platform_params[:linuxbridge_agent_service],
          :enable  => true,
          :ensure  => 'running',
          :require => 'Class[Neutron]'
        )
      end

      it 'does not configre VXLAN tunneling' do
        is_expected.to contain_neutron_agent_linuxbridge('vxlan/enable_vxlan').with_value(false)
        is_expected.to contain_neutron_agent_linuxbridge('vxlan/local_ip').with_ensure('absent')
        is_expected.to contain_neutron_agent_linuxbridge('vxlan/vxlan_group').with_ensure('absent')
        is_expected.to contain_neutron_agent_linuxbridge('vxlan/l2_population').with_ensure('absent')
      end
    end

    context 'with VXLAN tunneling enabled' do
      before do
        params.merge!({
          :tunnel_types  => ['vxlan'],
          :local_ip      => '192.168.0.10'
        })
      end

      context 'when providing all parameters' do
        it 'configures ml2_conf.ini' do
          is_expected.to contain_neutron_agent_linuxbridge('vxlan/enable_vxlan').with_value(true)
          is_expected.to contain_neutron_agent_linuxbridge('vxlan/local_ip').with_value(params[:local_ip])
          is_expected.to contain_neutron_agent_linuxbridge('vxlan/vxlan_group').with_value(default_params[:vxlan_group])
          is_expected.to contain_neutron_agent_linuxbridge('vxlan/vxlan_ttl').with_ensure('absent')
          is_expected.to contain_neutron_agent_linuxbridge('vxlan/vxlan_tos').with_ensure('absent')
          is_expected.to contain_neutron_agent_linuxbridge('vxlan/l2_population').with_value(default_params[:l2_population])
        end
      end

      context 'when not providing or overriding some parameters' do
        before do
          params.merge!({
            :vxlan_group   => '224.0.0.2',
            :vxlan_ttl     => 10,
            :vxlan_tos     => 2,
            :l2_population => true,
          })
        end

        it 'configures ml2_conf.ini' do
          is_expected.to contain_neutron_agent_linuxbridge('vxlan/enable_vxlan').with_value(true)
          is_expected.to contain_neutron_agent_linuxbridge('vxlan/local_ip').with_value(params[:local_ip])
          is_expected.to contain_neutron_agent_linuxbridge('vxlan/vxlan_group').with_value(params[:vxlan_group])
          is_expected.to contain_neutron_agent_linuxbridge('vxlan/vxlan_ttl').with_value(params[:vxlan_ttl])
          is_expected.to contain_neutron_agent_linuxbridge('vxlan/vxlan_tos').with_value(params[:vxlan_tos])
          is_expected.to contain_neutron_agent_linuxbridge('vxlan/l2_population').with_value(params[:l2_population])
        end
      end
    end

    context 'when providing the physical_interface_mappings parameter' do
      before do
        params.merge!(:physical_interface_mappings => ['physnet0:eth0', 'physnet1:eth1'])
      end

      it 'configures physical interface mappings' do
        is_expected.to contain_neutron_agent_linuxbridge('linux_bridge/physical_interface_mappings').with_value(
          params[:physical_interface_mappings].join(',')
        )
      end
    end

    context 'with firewall_driver parameter set to false' do
      before :each do
        params.merge!(:firewall_driver => false)
      end
      it 'removes firewall driver configuration' do
        is_expected.to contain_neutron_agent_linuxbridge('securitygroup/firewall_driver').with_ensure('absent')
      end
    end
  end

  context 'on Debian platforms' do
    let :facts do
      default_facts.merge({ :osfamily => 'Debian' })
    end

    let :platform_params do
      { :linuxbridge_agent_package => 'neutron-plugin-linuxbridge-agent',
        :linuxbridge_agent_service => 'neutron-plugin-linuxbridge-agent' }
    end

    it_configures 'neutron plugin linuxbridge agent with ml2 plugin'
  end

  context 'on RedHat platforms' do
    let :facts do
      default_facts.merge({ :osfamily => 'RedHat' })
    end

    let :platform_params do
      { :linuxbridge_server_package => 'openstack-neutron-linuxbridge',
        :linuxbridge_agent_service  => 'neutron-linuxbridge-agent' }
    end
  end
end
