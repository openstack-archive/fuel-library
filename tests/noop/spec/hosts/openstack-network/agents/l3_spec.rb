# ROLE: primary-neutron
# ROLE: neutron
# ROLE: compute

require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/agents/l3.pp'

describe manifest do

  before(:each) do
    Noop.puppet_function_load :is_pkg_installed
    MockFunction.new(:is_pkg_installed) do |function|
      allow(function).to receive(:call).and_return false
    end
    Noop.puppet_function_load :is_file_updated
    MockFunction.new('is_file_updated') { |function|
      allow(function).to receive(:call).and_return false
    }
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

            include_examples 'override_resources'
          else
            it { should_not contain_class('neutron::agents::l3') }
          end
        end

      elsif Noop.hiera('role') =~ /neutron/
        context 'with Neutron-l3-agent on neutron' do
          na_config = Noop.hiera_hash('neutron_advanced_configuration')
          dvr = na_config.fetch('neutron_dvr', false)
          agent_mode = (dvr  ?  'dvr_snat'  :  'legacy')
          ha_agent   = na_config.fetch('l3_agent_ha', true)

          l2pop = na_config.fetch('neutron_l2_pop', false)

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
              'primary' => (node_role == 'primary-neutron')
            )}
          else
            it { should_not contain_cluster__neutron__l3('default-l3') }
          end
        end

        include_examples 'override_resources'
      end
    end
  end
  test_ubuntu_and_centos manifest
end
