require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/compute-nova.pp'

# HIERA: neut_vlan.ceph.controller-ephemeral-ceph neut_vlan.ceph.compute-ephemeral-ceph
# FACTS: ubuntu

describe manifest do
  shared_examples 'catalog' do
    use_neutron = task.hiera('use_neutron', false)
    use_vcenter = task.hiera('use_vcenter', false)

    let(:nova_hash) do
      task.hiera_hash 'nova'
    end

    let(:nova_user_password) do
      nova_hash['user_password']
    end

    let(:network_scheme) do
      task.hiera_hash 'network_scheme'
    end

    let(:prepare_network_config) do
      task.puppet_function 'prepare_network_config', network_scheme
    end

    let(:bind_address) do
      task.puppet_function 'get_network_role_property', 'nova/api', 'ipaddr'
    end

    let(:nova_rate_limits) do
      task.hiera_hash 'nova_rate_limits'
    end

    let(:public_interface) do
      task.puppet_function('get_network_role_property', 'public/vip', 'interface') || ''
    end

    let(:private_interface) do
      task.puppet_function 'get_network_role_property', 'nova/private', 'interface'
    end

    let(:fixed_network_range) do
      task.hiera 'fixed_network_range'
    end

    let(:network_size) do
      task.hiera 'network_size', nil
    end

    let(:num_networks) do
      task.hiera 'num_networks', nil
    end

    let(:network_config) do
      task.hiera('network_config', {})
    end

    let(:dns_nameservers) do
      task.hiera_array('dns_nameservers', [])
    end

    let(:use_vcenter) do
      task.hiera 'use_vcenter', false
    end

    if task.hiera('use_neutron') && task.hiera('use_vcenter', false) && task.hiera('role') == 'compute'
      context 'if Vcenter+Neutron is used' do
        # TODO: neutron tests
      end
    elsif !task.hiera('use_neutron') && task.hiera('use_vcenter', false) && task.hiera('role') == 'compute'
      context 'if Vcenter+Nova-network is used' do
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
  end
  test_ubuntu_and_centos manifest
end

