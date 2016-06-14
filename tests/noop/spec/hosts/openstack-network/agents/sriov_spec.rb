# ROLE: compute

require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/agents/sriov.pp'

describe manifest do

  before(:each) do
    Noop.puppet_function_load :is_pkg_installed
    MockFunction.new(:is_pkg_installed) do |function|
      allow(function).to receive(:call).and_return false
    end
  end

  shared_examples 'catalog' do
    let(:network_scheme) do
      Noop.hiera_hash('network_scheme', {})
    end

    let(:prepare) do
      Noop.puppet_function('prepare_network_config', network_scheme)
    end

    let(:pci_passthrough) do
      prepare
      Noop.puppet_function('get_nic_passthrough_whitelist', 'sriov')
    end

    let(:adv_neutron_config) do
      Noop.hiera_hash('neutron_advanced_configuration', {})
    end

    context 'with Neutron SRIOV agent' do
      it 'configures SRIOV agent' do
        if pci_passthrough
          enable_qos = adv_neutron_config.fetch('neutron_qos', false)
          should contain_class('neutron::agents::ml2::sriov').with(
            'manage_service'           => true,
            'enabled'                  => true,
            'extensions'               => enable_qos ? ['qos'] : '',
            'physical_device_mappings' => Noop.puppet_function('nic_whitelist_to_mappings', pci_passthrough)
          )
        end
      end
    end
  end
  test_ubuntu_and_centos manifest
end

