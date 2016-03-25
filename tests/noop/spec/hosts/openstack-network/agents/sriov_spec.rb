# RUN: neut_gre.generate_vms ubuntu
# RUN: neut_vlan.ceph.ceil-compute.overridden_ssl ubuntu
# RUN: neut_vlan.ceph.compute-ephemeral-ceph ubuntu
# RUN: neut_vlan.cinder-block-device.compute ubuntu
# RUN: neut_vlan.compute.nossl ubuntu
# RUN: neut_vlan.compute.ssl ubuntu
# RUN: neut_vlan.compute.ssl.overridden ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-compute ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-compute ubuntu

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
    if Noop.hiera('use_neutron')

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

      context 'with Neutron SRIOV agent' do
        it 'configures SRIOV agent' do
          if pci_passthrough
            should contain_class('neutron::agents::ml2::sriov').with(
              'manage_service'           => true,
              'enabled'                  => true,
              'physical_device_mappings' => Noop.puppet_function('nic_whitelist_to_mappings', pci_passthrough)
            )
          end
        end
      end

    end
  end
  test_ubuntu_and_centos manifest
end

