# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-controller.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-compute.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-cinder.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-mongo.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-controller.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-controller.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-compute.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-ceph-osd.yaml ubuntu
# RUN: neut_vlan.ironic.controller.yaml ubuntu
# RUN: neut_vlan.ironic.conductor.yaml ubuntu
# RUN: neut_vlan.compute.ssl.yaml ubuntu
# RUN: neut_vlan.compute.ssl.overridden.yaml ubuntu
# RUN: neut_vlan.compute.nossl.yaml ubuntu
# RUN: neut_vlan.cinder-block-device.compute.yaml ubuntu
# RUN: neut_vlan.ceph.controller-ephemeral-ceph.yaml ubuntu
# RUN: neut_vlan.ceph.compute-ephemeral-ceph.yaml ubuntu
# RUN: neut_vlan.ceph.ceil-primary-controller.overridden_ssl.yaml ubuntu
# RUN: neut_vlan.ceph.ceil-compute.overridden_ssl.yaml ubuntu
# RUN: neut_gre.generate_vms.yaml ubuntu
require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/agents/dhcp.pp'

describe manifest do

  before(:each) do
    Noop.puppet_function_load :is_pkg_installed
    MockFunction.new(:is_pkg_installed) do |function|
      allow(function).to receive(:call).and_return false
    end
  end

  shared_examples 'catalog' do
    if (Noop.hiera('use_neutron') and Noop.hiera('role') =~ /controller/)

      let(:node_role) do
        Noop.hiera('role')
      end

      let(:configuration_override) do
        Noop.hiera_structure 'configuration'
      end

      let(:neutron_dhcp_agent_config_override_resources) do
        configuration_override.fetch('neutron_dhcp_agent_config', {})
      end

      context 'with Neutron-l3-agent on controller' do
        na_config = Noop.hiera_hash('neutron_advanced_configuration')
        neutron_config = Noop.hiera_hash('neutron_config')
        isolated_metadata = neutron_config.fetch('metadata',{}).fetch('isolated_metadata', true)
        ha_agent   = na_config.fetch('dhcp_agent_ha', true)

        it { should contain_class('neutron::agents::dhcp').with(
          'debug' => Noop.hiera('debug', true)
        )}
        it { should contain_class('neutron::agents::dhcp').with(
          'enabled' => true
        )}
        it { should contain_class('neutron::agents::dhcp').with(
          'manage_service' => true
        )}
        it { should contain_class('neutron::agents::dhcp').with(
          'dhcp_delete_namespaces' => true
        )}
        it { should contain_class('neutron::agents::dhcp').with(
          'resync_interval' => 30
        )}
        it { should contain_class('neutron::agents::dhcp').with(
          'enable_isolated_metadata' => isolated_metadata
        )}

        it 'neutron dhcp agent config should be modified by override_resources' do
          is_expected.to contain_override_resources('neutron_dhcp_agent_config').with(:data => neutron_dhcp_agent_config_override_resources)
        end

        it 'should use "override_resources" to update the catalog' do
          ral_catalog = Noop.create_ral_catalog self
          neutron_dhcp_agent_config_override_resources.each do |title, params|
            params['value'] = 'True' if params['value'].is_a? TrueClass
            expect(ral_catalog).to contain_neutron_dhcp_agent_config(title).with(params)
          end
        end

        if ha_agent
          it { should contain_class('cluster::neutron::dhcp').with(
            'primary' => (node_role == 'primary-controller')
          )}
        else
          it { should_not contain_class('cluster::neutron::dhcp') }
        end
      end
    end
  end
  test_ubuntu_and_centos manifest
end
