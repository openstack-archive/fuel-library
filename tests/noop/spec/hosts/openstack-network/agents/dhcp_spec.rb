# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/agents/dhcp.pp'

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
    if Noop.hiera('role') =~ /controller/

      let(:node_role) do
        Noop.hiera('role')
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
          'resync_interval' => 30
        )}
        it { should contain_class('neutron::agents::dhcp').with(
          'enable_isolated_metadata' => isolated_metadata
        )}

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
