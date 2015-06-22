require 'spec_helper'

describe 'nova::network::neutron' do

  let :default_params do
    { :neutron_auth_strategy           => 'keystone',
      :neutron_url                     => 'http://127.0.0.1:9696',
      :neutron_url_timeout             => '30',
      :neutron_admin_tenant_name       => 'services',
      :neutron_default_tenant_id       => 'default',
      :neutron_region_name             => 'RegionOne',
      :neutron_admin_username          => 'neutron',
      :neutron_admin_auth_url          => 'http://127.0.0.1:35357/v2.0',
      :neutron_ovs_bridge              => 'br-int',
      :neutron_extension_sync_interval => '600',
      :security_group_api              => 'neutron',
      :firewall_driver                 => 'nova.virt.firewall.NoopFirewallDriver',
      :vif_plugging_is_fatal           => true,
      :vif_plugging_timeout            => '300',
      :dhcp_domain                     => 'novalocal'
    }
  end

  let :params do
    { :neutron_admin_password => 's3cr3t' }
  end


  context 'with required parameters' do
    it 'configures neutron endpoint in nova.conf' do
      is_expected.to contain_nova_config('neutron/admin_password').with_value(params[:neutron_admin_password]).with_secret(true)
      is_expected.to contain_nova_config('DEFAULT/network_api_class').with_value('nova.network.neutronv2.api.API')
      is_expected.to contain_nova_config('DEFAULT/dhcp_domain').with_value(default_params[:dhcp_domain])
      is_expected.to contain_nova_config('neutron/auth_strategy').with_value(default_params[:neutron_auth_strategy])
      is_expected.to contain_nova_config('neutron/url').with_value(default_params[:neutron_url])
      is_expected.to contain_nova_config('neutron/url_timeout').with_value(default_params[:neutron_url_timeout])
      is_expected.to contain_nova_config('neutron/admin_tenant_name').with_value(default_params[:neutron_admin_tenant_name])
      is_expected.to contain_nova_config('neutron/default_tenant_id').with_value(default_params[:neutron_default_tenant_id])
      is_expected.to contain_nova_config('neutron/region_name').with_value(default_params[:neutron_region_name])
      is_expected.to contain_nova_config('neutron/admin_username').with_value(default_params[:neutron_admin_username])
      is_expected.to contain_nova_config('neutron/admin_auth_url').with_value(default_params[:neutron_admin_auth_url])
      is_expected.to contain_nova_config('neutron/extension_sync_interval').with_value(default_params[:neutron_extension_sync_interval])
    end
    it 'configures Nova to use Neutron Bridge Security Groups and Firewall' do
      is_expected.to contain_nova_config('DEFAULT/firewall_driver').with_value(default_params[:firewall_driver])
      is_expected.to contain_nova_config('DEFAULT/security_group_api').with_value(default_params[:security_group_api])
      is_expected.to contain_nova_config('neutron/ovs_bridge').with_value(default_params[:neutron_ovs_bridge])
    end
    it 'configures neutron vif plugging events in nova.conf' do
      is_expected.to contain_nova_config('DEFAULT/vif_plugging_is_fatal').with_value(default_params[:vif_plugging_is_fatal])
      is_expected.to contain_nova_config('DEFAULT/vif_plugging_timeout').with_value(default_params[:vif_plugging_timeout])
    end
  end

  context 'when overriding class parameters' do
    before do
      params.merge!(
        :neutron_url                     => 'http://10.0.0.1:9696',
        :neutron_url_timeout             => '30',
        :neutron_admin_tenant_name       => 'openstack',
        :neutron_default_tenant_id       => 'default',
        :neutron_region_name             => 'RegionTwo',
        :neutron_admin_username          => 'neutron2',
        :neutron_admin_auth_url          => 'http://10.0.0.1:35357/v2.0',
        :network_api_class               => 'network.api.class',
        :security_group_api              => 'nova',
        :firewall_driver                 => 'nova.virt.firewall.IptablesFirewallDriver',
        :neutron_ovs_bridge              => 'br-int',
        :neutron_extension_sync_interval => '600',
        :vif_plugging_is_fatal           => false,
        :vif_plugging_timeout            => '0',
	:dhcp_domain                     => 'foo'
      )
    end

    it 'configures neutron endpoint in nova.conf' do
      is_expected.to contain_nova_config('neutron/auth_strategy').with_value(default_params[:neutron_auth_strategy])
      is_expected.to contain_nova_config('neutron/admin_password').with_value(params[:neutron_admin_password]).with_secret(true)
      is_expected.to contain_nova_config('DEFAULT/network_api_class').with_value('network.api.class')
      is_expected.to contain_nova_config('DEFAULT/dhcp_domain').with_value(params[:dhcp_domain])
      is_expected.to contain_nova_config('neutron/url').with_value(params[:neutron_url])
      is_expected.to contain_nova_config('neutron/url_timeout').with_value(params[:neutron_url_timeout])
      is_expected.to contain_nova_config('neutron/admin_tenant_name').with_value(params[:neutron_admin_tenant_name])
      is_expected.to contain_nova_config('neutron/default_tenant_id').with_value(params[:neutron_default_tenant_id])
      is_expected.to contain_nova_config('neutron/region_name').with_value(params[:neutron_region_name])
      is_expected.to contain_nova_config('neutron/admin_username').with_value(params[:neutron_admin_username])
      is_expected.to contain_nova_config('neutron/admin_auth_url').with_value(params[:neutron_admin_auth_url])
      is_expected.to contain_nova_config('neutron/extension_sync_interval').with_value(params[:neutron_extension_sync_interval])
    end
    it 'configures Nova to use Neutron Security Groups and Firewall' do
      is_expected.to contain_nova_config('DEFAULT/firewall_driver').with_value(params[:firewall_driver])
      is_expected.to contain_nova_config('DEFAULT/security_group_api').with_value(params[:security_group_api])
      is_expected.to contain_nova_config('neutron/ovs_bridge').with_value(params[:neutron_ovs_bridge])
    end
    it 'configures neutron vif plugging events in nova.conf' do
      is_expected.to contain_nova_config('DEFAULT/vif_plugging_is_fatal').with_value(params[:vif_plugging_is_fatal])
      is_expected.to contain_nova_config('DEFAULT/vif_plugging_timeout').with_value(params[:vif_plugging_timeout])
    end
  end
end
