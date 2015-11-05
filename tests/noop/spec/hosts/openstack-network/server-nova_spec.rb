require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/server-nova.pp'

describe manifest do
  shared_examples 'catalog' do

    # let(:facts) {
    #   Noop.ubuntu_facts.merge({
    #     :processorcount => '6',
    #     :fqdn => 'node-xxx',
    #   })
    # }

    # let(:processorcount) do
    #   6
    # end

    context 'setup Nova for using Neutron on controller', :if => (Noop.hiera('use_neutron') and Noop.hiera('role') =~ /controller/) do

      na_config = Noop.hiera_hash('neutron_advanced_configuration')
      neutron_config = Noop.hiera_hash('neutron_config')

      floating_net = neutron_config.fetch('default_floating_net', 'net04_ext')
      ks  = neutron_config.fetch('keystone', {})
      admin_password     = ks.fetch('admin_password')
      admin_tenant_name  = ks.fetch('admin_tenant', 'services')
      admin_username     = ks.fetch('admin_user', 'neutron')
      region_name        = Noop.hiera('region', 'RegionOne')
      management_vip     = Noop.hiera('management_vip')
      service_endpoint   = Noop.hiera('service_endpoint', management_vip)
      neutron_endpoint   = Noop.hiera('neutron_endpoint', management_vip)
      auth_api_version   = 'v2.0'
      admin_identity_uri = "http://#{service_endpoint}:35357"
      admin_auth_url     = "#{admin_identity_uri}/#{auth_api_version}"
      neutron_url        = "http://#{neutron_endpoint}:9696"
      it { should contain_service('nova-api').with(
        'ensure' => 'running'
      )}
      it { should contain_nova_config('DEFAULT/default_floating_pool').with(
        'value' => floating_net
      ).that_notifies('Service[nova-api]')}
      it { should contain_class('nova::network::neutron').with(
        'neutron_admin_password' => admin_password
      )}
      it { should contain_class('nova::network::neutron').with(
        'neutron_admin_tenant_name' => admin_tenant_name
      )}
      it { should contain_class('nova::network::neutron').with(
        'neutron_region_name' => region_name
      )}
      it { should contain_class('nova::network::neutron').with(
        'neutron_admin_username' => admin_username
      )}
      it { should contain_class('nova::network::neutron').with(
        'neutron_admin_auth_url' => admin_auth_url
      )}
      it { should contain_class('nova::network::neutron').with(
        'neutron_url' => neutron_url
      )}
      it { should contain_class('nova::network::neutron').with(
        'neutron_ovs_bridge' => 'br-int'
      )}
    end

    context 'setup Nova-network on controller', :if => (!Noop.hiera('use_neutron') and Noop.hiera('role') =~ /controller/) do

      private_interface = Noop.hiera('private_int')
      public_interface  = Noop.hiera('public_int')
      fixed_range       = Noop.hiera('fixed_network_range')
      network_manager   = Noop.hiera('network_manager')
      network_config    = Noop.hiera('network_config', {})
      num_networks      = Noop.hiera('num_networks')
      network_size      = Noop.hiera('network_size')
      nameservers       = Noop.hiera_array('dns_nameservers', [])

      it { should contain_nova_config('DEFAULT/force_snat_range').with(
        'value' => '0.0.0.0/0'
      )}
      it { should contain_class('nova::network').with(
        'ensure_package' => 'installed'
      )}
      it { should contain_class('nova::network').with(
        'enabled' => false
      )}
      it { should contain_class('nova::network').with(
        'create_networks' => true
      )}
      it { should contain_class('nova::network').with(
        'floating_range' => false
      )}
      it { should contain_class('nova::network').with(
        'private_interface' => private_interface
      )}
      it { should contain_class('nova::network').with(
        'public_interface' => '' # because controller
      )}
      it { should contain_class('nova::network').with(
        'fixed_range' => fixed_range
      )}
      it { should contain_class('nova::network').with(
        'network_manager' => network_manager
      )}
      it { should contain_class('nova::network').with(
        'config_overrides' => network_config
      )}
      it { should contain_class('nova::network').with(
        'num_networks' => num_networks
      )}
      it { should contain_class('nova::network').with(
        'network_size' => network_size
      )}
      it { should contain_class('nova::network').with(
        'dns1' => nameservers[0]
      )}
      it { should contain_class('nova::network').with(
        'dns2' => nameservers[1]
      )}
    end
  end
  test_ubuntu_and_centos manifest
end

