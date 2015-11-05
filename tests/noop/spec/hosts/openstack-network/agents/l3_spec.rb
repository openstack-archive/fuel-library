require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/agents/l3.pp'

describe manifest do
  shared_examples 'catalog' do
    if (Noop.hiera('use_neutron') and Noop.hiera('role') =~ /controller|compute/)

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

      context 'with DVR neutron-l3-agent on compute' do

      end

      context 'with Neutron-l3-agent' do
        role = Noop.hiera('role')
        neutron_config = Noop.hiera_hash('neutron_config')
        adv_neutron_config = Noop.hiera_hash('neutron_advanced_configuration')
        pnets = neutron_config.fetch('L2',{}).fetch('phys_nets',{})

  # $ha_agent                = try_get_value($neutron_advanced_config, 'l3_agent_ha', true)

  # class { 'neutron::agents::l3':
  #   debug                    => $debug,
  #   metadata_port            => $metadata_port,
  #   external_network_bridge  => br_floating,
  #   manage_service           => true,
  #   enabled                  => true,
  #   router_delete_namespaces => true,
  #   agent_mode               => $agent_mode,
  # }

  # if $ha_agent {
  #   $primary_controller = hiera('primary_controller')
  #   cluster::neutron::l3 { 'default-l3' :
  #     primary => $primary_controller,
  #   }
  # }


      end
    end
  end
  test_ubuntu_and_centos manifest
end

