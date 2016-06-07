# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/server-config.pp'

describe manifest do

  before(:each) do
    Noop.puppet_function_load :is_pkg_installed
    MockFunction.new(:is_pkg_installed) do |function|
      allow(function).to receive(:call).and_return false
    end
  end

  shared_examples 'catalog' do
    if (Noop.hiera('use_neutron') == true and Noop.hiera('role') =~ /controller/)
      let(:network_scheme) do
        Noop.hiera_hash('network_scheme', {})
      end

      let(:configuration_override) do
        Noop.hiera_structure 'configuration'
      end

      let(:neutron_config_override_resources) do
        configuration_override.fetch('neutron_config', {})
      end

      let(:neutron_api_config_override_resources) do
        configuration_override.fetch('neutron_api_config', {})
      end

      let(:neutron_plugin_ml2_override_resources) do
        configuration_override.fetch('neutron_plugin_ml2', {})
      end

      context 'with Neutron-server' do
        neutron_config   = Noop.hiera_hash('neutron_config')
        segmentation_type = neutron_config.fetch('L2',{}).fetch('segmentation_type')
        pnets = neutron_config.fetch('L2',{}).fetch('phys_nets',{})
        path_mtu = neutron_config.fetch('L2',{}).fetch('path_mtu', nil)

        it { should contain_class('neutron::plugins::ml2').with(
          'path_mtu' => path_mtu,
        )}

      end
    end
  end
  test_ubuntu_and_centos manifest
end
