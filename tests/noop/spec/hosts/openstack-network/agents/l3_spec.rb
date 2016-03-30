# HIERA: neut_gre.generate_vms
# HIERA: neut_vlan.ceph.ceil-compute.overridden_ssl
# HIERA: neut_vlan.ceph.ceil-primary-controller.overridden_ssl
# HIERA: neut_vlan.ceph.compute-ephemeral-ceph
# HIERA: neut_vlan.ceph.controller-ephemeral-ceph
# HIERA: neut_vlan.cinder-block-device.compute
# HIERA: neut_vlan.compute.nossl
# HIERA: neut_vlan.compute.ssl
# HIERA: neut_vlan.compute.ssl.overridden
# HIERA: neut_vlan.ironic.controller
# HIERA: neut_vlan_l3ha.ceph.ceil-compute
# HIERA: neut_vlan_l3ha.ceph.ceil-controller
# HIERA: neut_vlan_l3ha.ceph.ceil-primary-controller
# HIERA: neut_vxlan_dvr.murano.sahara-compute
# HIERA: neut_vxlan_dvr.murano.sahara-controller
# HIERA: neut_vxlan_dvr.murano.sahara-primary-controller
# HIERA: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl

require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/agents/l3.pp'

describe manifest do

  before(:each) do
    Noop.puppet_function_load :is_pkg_installed
    MockFunction.new(:is_pkg_installed) do |function|
      allow(function).to receive(:call).and_return false
    end
  end

  shared_examples 'catalog' do
    if Noop.hiera('use_neutron')

      let(:node_role) do
        Noop.hiera('role')
      end

      let(:network_scheme) do
        Noop.hiera_hash('network_scheme', {})
      end

      let(:prepare) do
        Noop.puppet_function('prepare_network_config', network_scheme)
      end

      let(:br_floating) do
        prepare
        Noop.puppet_function('get_network_role_property', 'neutron/floating', 'interface')
      end

      if Noop.hiera('role') == 'compute'
        context 'neutron-l3-agent on compute' do
          na_config = Noop.hiera_hash('neutron_advanced_configuration')
          dvr = na_config.fetch('neutron_dvr', false)
          if dvr
            let(:configuration_override) do
              Noop.hiera_structure 'configuration'
            end

            let(:neutron_l3_agent_config_override_resources) do
              configuration_override.fetch('neutron_l3_agent_config', {})
            end

            it 'neutron l3 agent config should be modified by override_resources' do
              is_expected.to contain_override_resources('neutron_l3_agent_config').with(:data => neutron_l3_agent_config_override_resources)
            end

            it 'should use "override_resources" to update the catalog' do
              ral_catalog = Noop.create_ral_catalog self
              neutron_l3_agent_config_override_resources.each do |title, params|
                params['value'] = 'True' if params['value'].is_a? TrueClass
                expect(ral_catalog).to contain_neutron_l3_agent_config(title).with(params)
              end
            end

            l2pop = na_config.fetch('neutron_l2_pop', false)
            it { should contain_class('neutron::agents::l3').with(
              'agent_mode' => 'dvr',
            )}
            it { should contain_class('neutron::agents::l3').with(
              'manage_service' => true
            )}
            it { should contain_class('neutron::agents::l3').with(
              'metadata_port' => '8775'
            )}
            it { should contain_class('neutron::agents::l3').with(
              'enabled' => true
            )}
            it { should contain_class('neutron::agents::l3').with(
              'debug' => Noop.hiera('debug', true)
            )}
            it { should contain_class('neutron::agents::l3').with(
              'external_network_bridge' => ' ' # should be present and empty
            )}
            it { should_not contain_cluster__neutron__l3('default-l3') }
          else
            it { should_not contain_class('neutron::agents::l3') }
          end
        end

      elsif Noop.hiera('role') =~ /controller/
        context 'with Neutron-l3-agent on controller' do
          na_config = Noop.hiera_hash('neutron_advanced_configuration')
          dvr = na_config.fetch('neutron_dvr', false)
          agent_mode = (dvr  ?  'dvr_snat'  :  'legacy')
          ha_agent   = na_config.fetch('l3_agent_ha', true)

          l2pop = na_config.fetch('neutron_l2_pop', false)

          let(:configuration_override) do
            Noop.hiera_structure 'configuration'
          end

          let(:neutron_l3_agent_config_override_resources) do
            configuration_override.fetch('neutron_l3_agent_config', {})
          end

          it 'neutron l3 agent config should be modified by override_resources' do
            is_expected.to contain_override_resources('neutron_l3_agent_config').with(:data => neutron_l3_agent_config_override_resources)
          end

          it 'should use "override_resources" to update the catalog' do
            ral_catalog = Noop.create_ral_catalog self
            neutron_l3_agent_config_override_resources.each do |title, params|
              params['value'] = 'True' if params['value'].is_a? TrueClass
              expect(ral_catalog).to contain_neutron_l3_agent_config(title).with(params)
            end
          end

          it { should contain_class('neutron::agents::l3').with(
            'agent_mode' => agent_mode
          )}
          it { should contain_class('neutron::agents::l3').with(
            'manage_service' => true
          )}
          it { should contain_class('neutron::agents::l3').with(
            'metadata_port' => '8775'
          )}
          it { should contain_class('neutron::agents::l3').with(
            'enabled' => true
          )}
          it { should contain_class('neutron::agents::l3').with(
            'debug' => Noop.hiera('debug', true)
          )}
          it { should contain_class('neutron::agents::l3').with(
            'external_network_bridge' => ' ' # should be present and empty
          )}

          if ha_agent
            it { should contain_cluster__neutron__l3('default-l3').with(
              'primary' => (node_role == 'primary-controller')
            )}
          else
            it { should_not contain_cluster__neutron__l3('default-l3') }
          end
        end
      end
    end
  end
  test_ubuntu_and_centos manifest
end
