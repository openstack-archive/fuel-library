require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/compute-nova.pp'

describe manifest do
  shared_examples 'catalog' do
    use_neutron = Noop.hiera('use_neutron', false)
    use_vcenter = Noop.hiera('use_vcenter', false)

    let(:nova_hash) do
      Noop.hiera_hash 'nova'
    end

    let(:nova_user_password) do
      nova_hash['user_password']
    end

    let(:network_scheme) do
      Noop.hiera_hash 'network_scheme'
    end

    let(:prepare_network_config) do
      Noop.puppet_function 'prepare_network_config', network_scheme
    end

    let(:bind_address) do
      Noop.puppet_function 'get_network_role_property', 'nova/api', 'ipaddr'
    end

    let(:nova_rate_limits) do
      Noop.hiera_hash 'nova_rate_limits'
    end

    let(:public_interface) do
      Noop.puppet_function('get_network_role_property', 'public/vip', 'interface') || ''
    end

    let(:private_interface) do
      Noop.puppet_function 'get_network_role_property', 'nova/private', 'interface'
    end

    let(:fixed_network_range) do
      Noop.hiera 'fixed_network_range'
    end

    let(:network_size) do
      Noop.hiera 'network_size', nil
    end

    let(:num_networks) do
      Noop.hiera 'num_networks', nil
    end

    let(:network_config) do
      Noop.hiera('network_config', {})
    end

    let(:dns_nameservers) do
      Noop.hiera_array('dns_nameservers', [])
    end

    let(:use_vcenter) do
      Noop.hiera 'use_vcenter', false
    end

    context 'if Neutron is used', :if => use_neutron do
      # TODO: neutron tests
    end

    context 'if Nova-network is used', :if => (not use_neutron) do
      context 'if VCenter is not used', :if => (not use_vcenter and not use_neutron) do
        it {
          expect(subject).to contain_nova_config('DEFAULT/multi_host').with(:value => 'True')
        }
        it {
          expect(subject).to contain_nova_config('DEFAULT/send_arp_for_ha').with(:value => 'True')
        }

        #it { expect(subject).to contain_nova_config('DEFAULT/metadata_host').with(:value  => bind_address) }

        it do
          expect(subject).to contain_class('Nova::Api').with(
                                 :ensure_package => "installed",
                                 :enabled => true,
                                 :admin_tenant_name => "services",
                                 :admin_user => "nova",
                                 :admin_password => nova_user_password,
                                 :enabled_apis => "metadata",
                                 :api_bind_address => bind_address,
                                 :ratelimits => nova_rate_limits,
                             )
        end
      end

      it {
        expect(subject).to contain_nova_config('DEFAULT/force_snat_range').with(:value => '0.0.0.0/0')
      }

      it do
        expect(subject).to contain_class('Nova::Network').with(
                               :ensure_package => "installed",
                               :public_interface => public_interface,
                               :private_interface => private_interface,
                               :fixed_range => fixed_network_range,
                               :floating_range => false,
                               :network_manager => "nova.network.manager.FlatDHCPManager",
                               :config_overrides => network_config,
                               :create_networks => true,
                               :num_networks => num_networks,
                               :network_size => network_size,
                               :dns1 => dns_nameservers[0],
                               :dns2 => dns_nameservers[1],
                               :enabled => true,
                               :install_service => true,
                           )
      end
    end

  end
  test_ubuntu_and_centos manifest
end

