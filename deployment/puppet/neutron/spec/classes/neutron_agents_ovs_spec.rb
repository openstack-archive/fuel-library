require 'spec_helper'

describe 'neutron::agents::ovs' do

  let :pre_condition do
    "class { 'neutron': rabbit_password => 'passw0rd' }\n" +
    "class { 'neutron::plugins::ovs': network_vlan_ranges => 'physnet1:1000:2000' }"
  end

  let :default_params do
    { :package_ensure       => 'present',
      :manage_service       => true,
      :enabled              => true,
      :bridge_uplinks       => [],
      :bridge_mappings      => [],
      :integration_bridge   => 'br-int',
      :enable_tunneling     => false,
      :local_ip             => false,
      :tunnel_bridge        => 'br-tun',
      :polling_interval     => 2,
      :firewall_driver      => 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver',
      :veth_mtu             => ''
    }
  end

  let :params do
    {}
  end

  shared_examples_for 'neutron plugin ovs agent' do
    let :p do
      default_params.merge(params)
    end

    it { should contain_class('neutron::params') }

    it 'configures ovs_neutron_plugin.ini' do
      should contain_neutron_plugin_ovs('AGENT/polling_interval').with_value(p[:polling_interval])
      should contain_neutron_plugin_ovs('OVS/integration_bridge').with_value(p[:integration_bridge])
      should contain_neutron_plugin_ovs('SECURITYGROUP/firewall_driver').\
        with_value(p[:firewall_driver])
      should contain_neutron_plugin_ovs('OVS/enable_tunneling').with_value(false)
      should contain_neutron_plugin_ovs('OVS/tunnel_bridge').with_ensure('absent')
      should contain_neutron_plugin_ovs('OVS/local_ip').with_ensure('absent')
      should contain_neutron_plugin_ovs('AGENT/veth_mtu').with_ensure('absent')
    end

    it 'configures vs_bridge' do
      should contain_vs_bridge(p[:integration_bridge]).with_ensure('present')
    end

    it 'installs neutron ovs agent package' do
      if platform_params.has_key?(:ovs_agent_package)
        should contain_package('neutron-plugin-ovs-agent').with(
          :name   => platform_params[:ovs_agent_package],
          :ensure => p[:package_ensure]
        )
        should contain_package('neutron-plugin-ovs-agent').with_before(/Neutron_plugin_ovs\[.+\]/)
      else
        should contain_package('neutron-plugin-ovs').with_before(/Neutron_plugin_ovs\[.+\]/)
      end
    end

    it 'configures neutron ovs agent service' do
      should contain_service('neutron-plugin-ovs-service').with(
        :name    => platform_params[:ovs_agent_service],
        :enable  => true,
        :ensure  => 'running',
        :require => 'Class[Neutron]'
      )
    end

    context 'with veth_mtu set' do
      before :each do
        params.merge(:veth_mtu => '9000')
      end

      it 'should set the veth_mtu on the ovs agent' do
        should contain_neutron_plugin_ovs('AGENT/veth_mtu').with_value(params[:veth_mtu])
      end
    end

    context 'when not installing ovs agent package' do
      before :each do
        params.merge!(:package_ensure => 'absent')
      end
      it 'uninstalls neutron ovs agent package' do
        if platform_params.has_key?(:ovs_agent_package)
          should contain_package('neutron-plugin-ovs-agent').with(
            :name   => platform_params[:ovs_agent_package],
            :ensure => p[:package_ensure]
          )
        end
      end
    end

    context 'when supplying a firewall driver' do
      before :each do
        params.merge!(:firewall_driver => false)
      end
      it 'should configure firewall driver' do
        should contain_neutron_plugin_ovs('SECURITYGROUP/firewall_driver').with_ensure('absent')
      end
    end

    context 'when supplying bridge mappings for provider networks' do
      before :each do
        params.merge!(:bridge_uplinks => ['br-ex:eth2'],:bridge_mappings => ['default:br-ex'])
      end

      it 'configures bridge mappings' do
        should contain_neutron_plugin_ovs('OVS/bridge_mappings')
      end

      it 'should configure bridge mappings' do
        should contain_neutron__plugins__ovs__bridge(params[:bridge_mappings].join(',')).with(
          :before => 'Service[neutron-plugin-ovs-service]'
        )
      end

      it 'should configure bridge uplinks' do
        should contain_neutron__plugins__ovs__port(params[:bridge_uplinks].join(',')).with(
          :before => 'Service[neutron-plugin-ovs-service]'
        )
      end
    end

    context 'when enabling tunneling' do
      context 'without local ip address' do
        before :each do
          params.merge!(:enable_tunneling => true)
        end
        it 'should fail' do
          expect do
            subject
          end.to raise_error(Puppet::Error, /Local ip for ovs agent must be set when tunneling is enabled/)
        end
      end
      context 'with default params' do
        before :each do
          params.merge!(:enable_tunneling => true, :local_ip => '127.0.0.1' )
        end
        it 'should configure ovs for tunneling' do
          should contain_neutron_plugin_ovs('OVS/enable_tunneling').with_value(true)
          should contain_neutron_plugin_ovs('OVS/tunnel_bridge').with_value(default_params[:tunnel_bridge])
          should contain_neutron_plugin_ovs('OVS/local_ip').with_value('127.0.0.1')
          should contain_vs_bridge(default_params[:tunnel_bridge]).with_ensure('present')
        end
      end

      context 'with vxlan tunneling' do
        before :each do
          params.merge!(:enable_tunneling => true,
                        :local_ip => '127.0.0.1',
                        :tunnel_types => ['vxlan'],
                        :vxlan_udp_port => '4789')
        end

        it 'should perform vxlan network configuration' do
          should contain_neutron_plugin_ovs('agent/tunnel_types').with_value(params[:tunnel_types])
          should contain_neutron_plugin_ovs('agent/vxlan_udp_port').with_value(params[:vxlan_udp_port])
        end
      end
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      { :ovs_agent_package => 'neutron-plugin-openvswitch-agent',
        :ovs_agent_service => 'neutron-plugin-openvswitch-agent' }
    end

    it_configures 'neutron plugin ovs agent'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :ovs_cleanup_service => 'neutron-ovs-cleanup',
        :ovs_agent_service   => 'neutron-openvswitch-agent' }
    end

    it_configures 'neutron plugin ovs agent'
    it 'configures neutron ovs cleanup service' do
      should contain_service('ovs-cleanup-service').with(
        :name    => platform_params[:ovs_cleanup_service],
        :enable  => true
      )
      should contain_package('neutron-plugin-ovs').with_before(/Service\[ovs-cleanup-service\]/)
    end

  end
end
