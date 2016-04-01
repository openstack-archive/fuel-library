# RUN: neut_tun.ceph.murano.sahara.ceil-controller ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-primary-controller ubuntu
# RUN: neut_tun.ironic-primary-controller ubuntu
# RUN: neut_tun.l3ha-primary-controller ubuntu
# RUN: neut_vlan.ceph-primary-controller ubuntu
# RUN: neut_vlan.dvr-primary-controller ubuntu
# RUN: neut_vlan.murano.sahara.ceil-controller ubuntu
# RUN: neut_vlan.murano.sahara.ceil-primary-controller ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-compute ubuntu
# RUN: neut_vlan.ceph-compute ubuntu
# RUN: neut_vlan.murano.sahara.ceil-compute ubuntu
# R_N: neut_gre.generate_vms ubuntu

require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/agents/metadata.pp'

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

      let(:configuration_override) do
        Noop.hiera_structure 'configuration'
      end

      na_config                = Noop.hiera_hash('neutron_advanced_configuration', {})
      neutron_config           = Noop.hiera_hash('neutron_config')
      neutron_controller_roles = Noop.hiera('neutron_controller_nodes', ['controller', 'primary-controller'])
      neutron_compute_roles    = Noop.hiera('neutron_compute_nodes', ['compute'])
      isolated_metadata        = neutron_config.fetch('metadata',{}).fetch('isolated_metadata', true)
      ha_agent                 = na_config.fetch('dhcp_agent_ha', true)

      secret = neutron_config.fetch('metadata',{}).fetch('metadata_proxy_shared_secret')

      management_vip = Noop.hiera('management_vip')
      nova_endpoint  = Noop.hiera('nova_endpoint', management_vip)

      if neutron_compute_roles.include?(Noop.hiera('role'))
        context 'neutron-metadata-agent on compute' do
          na_config = Noop.hiera_hash('neutron_advanced_configuration')
          dvr = na_config.fetch('neutron_dvr', false)
          if dvr
            let(:neutron_metadata_agent_config_override_resources) do
              configuration_override.fetch('neutron_metadata_agent_config', {})
            end

            it { should contain_class('neutron::agents::metadata').with(
              'debug' => Noop.hiera('debug', true)
            )}
            it { should contain_class('neutron::agents::metadata').with(
              'enabled' => true
            )}
            it { should contain_class('neutron::agents::metadata').with(
              'manage_service' => true
            )}
            it { should contain_class('neutron::agents::metadata').with(
              'metadata_ip' => nova_endpoint
            )}
            it { should contain_class('neutron::agents::metadata').with(
              'shared_secret' => secret
            )}
            it 'neutron metadata agent config should be modified by override_resources' do
              is_expected.to contain_override_resources('neutron_metadata_agent_config').with(:data => neutron_metadata_agent_config_override_resources)
            end
            it 'should use "override_resources" to update the catalog' do
              ral_catalog = Noop.create_ral_catalog self
              neutron_metadata_agent_config_override_resources.each do |title, params|
                params['value'] = 'True' if params['value'].is_a? TrueClass
                expect(ral_catalog).to contain_neutron_metadata_agent_config(title).with(params)
              end
            end
          else
            it { should_not contain_class('neutron::agents::metadata') }
          end
          it { should_not contain_class('cluster::neutron::metadata') }
        end
      elsif neutron_controller_roles.include?(Noop.hiera('role'))
        context 'with neutron-metadata-agent on controller' do

          let(:neutron_metadata_agent_config_override_resources) do
            configuration_override.fetch('neutron_metadata_agent_config', {})
          end

          it 'neutron metadata agent config should be modified by override_resources' do
            is_expected.to contain_override_resources('neutron_metadata_agent_config').with(:data => neutron_metadata_agent_config_override_resources)
          end
          it 'should use "override_resources" to update the catalog' do
            ral_catalog = Noop.create_ral_catalog self
            neutron_metadata_agent_config_override_resources.each do |title, params|
              params['value'] = 'True' if params['value'].is_a? TrueClass
              expect(ral_catalog).to contain_neutron_metadata_agent_config(title).with(params)
            end
          end

          it { should contain_class('neutron::agents::metadata').with(
            'debug' => Noop.hiera('debug', true)
          )}
          it { should contain_class('neutron::agents::metadata').with(
            'enabled' => true
          )}
          it { should contain_class('neutron::agents::metadata').with(
            'manage_service' => true
          )}
          it { should contain_class('neutron::agents::metadata').with(
            'metadata_ip' => nova_endpoint
          )}
          it { should contain_class('neutron::agents::metadata').with(
            'shared_secret' => secret
          )}
          if ha_agent
            it { should contain_class('cluster::neutron::metadata').with(
              'primary' => (node_role == 'primary-controller')
            )}
          else
            it { should_not contain_class('cluster::neutron::metadata') }
          end
        end
      end
    end
  end
  test_ubuntu_and_centos manifest
end
