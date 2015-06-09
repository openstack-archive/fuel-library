require 'spec_helper'

describe 'neutron::agents::l3' do

  let :pre_condition do
    "class { 'neutron': rabbit_password => 'passw0rd' }"
  end

  let :default_params do
    { :package_ensure                   => 'present',
      :enabled                          => true,
      :debug                            => false,
      :external_network_bridge          => 'br-ex',
      :use_namespaces                   => true,
      :interface_driver                 => 'neutron.agent.linux.interface.OVSInterfaceDriver',
      :router_id                        => nil,
      :gateway_external_network_id      => nil,
      :handle_internal_only_routers     => true,
      :metadata_port                    => '9697',
      :send_arp_for_ha                  => '3',
      :periodic_interval                => '40',
      :periodic_fuzzy_delay             => '5',
      :enable_metadata_proxy            => true,
      :network_device_mtu               => nil,
      :router_delete_namespaces         => false,
      :ha_enabled                       => false,
      :ha_vrrp_auth_type                => 'PASS',
      :ha_vrrp_auth_password            => nil,
      :ha_vrrp_advert_int               => '3',
      :agent_mode                       => 'legacy',
      :allow_automatic_l3agent_failover => false }
  end

  let :params do
    { }
  end

  shared_examples_for 'neutron l3 agent' do
    let :p do
      default_params.merge(params)
    end

    it { should contain_class('neutron::params') }

    it 'configures l3_agent.ini' do
      should contain_neutron_l3_agent_config('DEFAULT/debug').with_value(p[:debug])
      should contain_neutron_l3_agent_config('DEFAULT/external_network_bridge').with_value(p[:external_network_bridge])
      should contain_neutron_l3_agent_config('DEFAULT/use_namespaces').with_value(p[:use_namespaces])
      should contain_neutron_l3_agent_config('DEFAULT/interface_driver').with_value(p[:interface_driver])
      should contain_neutron_l3_agent_config('DEFAULT/router_id').with_value(p[:router_id])
      should contain_neutron_l3_agent_config('DEFAULT/gateway_external_network_id').with_value(p[:gateway_external_network_id])
      should contain_neutron_l3_agent_config('DEFAULT/handle_internal_only_routers').with_value(p[:handle_internal_only_routers])
      should contain_neutron_l3_agent_config('DEFAULT/metadata_port').with_value(p[:metadata_port])
      should contain_neutron_l3_agent_config('DEFAULT/send_arp_for_ha').with_value(p[:send_arp_for_ha])
      should contain_neutron_l3_agent_config('DEFAULT/periodic_interval').with_value(p[:periodic_interval])
      should contain_neutron_l3_agent_config('DEFAULT/periodic_fuzzy_delay').with_value(p[:periodic_fuzzy_delay])
      should contain_neutron_l3_agent_config('DEFAULT/enable_metadata_proxy').with_value(p[:enable_metadata_proxy])
      should contain_neutron_l3_agent_config('DEFAULT/network_device_mtu').with_ensure('absent')
      should contain_neutron_l3_agent_config('DEFAULT/router_delete_namespaces').with_value(p[:router_delete_namespaces])
      should contain_neutron_l3_agent_config('DEFAULT/allow_automatic_l3agent_failover').with_value(p[:allow_automatic_l3agent_failover])
    end

    it 'installs neutron l3 agent package' do
      if platform_params.has_key?(:l3_agent_package)
        should contain_package('neutron-l3').with(
          :name    => platform_params[:l3_agent_package],
          :ensure  => p[:package_ensure],
          :require => 'Package[neutron]'
        )
        should contain_package('neutron-l3').with_before(/Neutron_l3_agent_config\[.+\]/)
      else
        should contain_package('neutron').with_before(/Neutron_l3_agent_config\[.+\]/)
      end
    end

    it 'configures neutron l3 agent service' do
      should contain_service('neutron-l3').with(
        :name    => platform_params[:l3_agent_service],
        :enable  => true,
        :ensure  => 'running',
        :require => 'Class[Neutron]'
      )
    end

    context 'with manage_service as false' do
      before :each do
        params.merge!(:manage_service => false)
      end
      it 'should not start/stop service' do
        should contain_service('neutron-l3').without_ensure
      end
    end

    context 'with DVR' do
      before :each do
        params.merge!(:agent_mode => 'dvr')
      end
      it 'should enable DVR mode' do
        should contain_neutron_l3_agent_config('DEFAULT/agent_mode').with_value(p[:agent_mode])
      end
    end

    context 'with HA routers' do
      before :each do
        params.merge!(:ha_enabled            => true,
                      :ha_vrrp_auth_password => 'secrete')
      end
      it 'should configure VRRP' do
        should contain_neutron_l3_agent_config('DEFAULT/ha_vrrp_auth_type').with_value(p[:ha_vrrp_auth_type])
        should contain_neutron_l3_agent_config('DEFAULT/ha_vrrp_auth_password').with_value(p[:ha_vrrp_auth_password])
        should contain_neutron_l3_agent_config('DEFAULT/ha_vrrp_advert_int').with_value(p[:ha_vrrp_advert_int])
      end
    end
  end

  shared_examples_for 'neutron l3 agent with network_device_mtu specified' do
    before do
      params.merge!(
        :network_device_mtu => 9999
      )
    end
    it 'configures network_device_mtu' do
      should contain_neutron_l3_agent_config('DEFAULT/network_device_mtu').with_value(params[:network_device_mtu])
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      { :l3_agent_package => 'neutron-l3-agent',
        :l3_agent_service => 'neutron-l3-agent' }
    end

    it_configures 'neutron l3 agent'
    it_configures 'neutron l3 agent with network_device_mtu specified'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :l3_agent_service => 'neutron-l3-agent' }
    end

    it_configures 'neutron l3 agent'
    it_configures 'neutron l3 agent with network_device_mtu specified'
  end
end
