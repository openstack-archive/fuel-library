require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/plugins/ml2.pp'

describe manifest do
    shared_examples 'catalog' do
      if Noop.hiera('use_neutron')
        neutron_config =  Noop.hiera_structure 'quantum_settings'
        pnets = neutron_config['L2']['phys_nets']
        segmentation_type = neutron_config['L2']['segmentation_type']

        if segmentation_type == 'vlan'
          physnet2 = "physnet2:#{pnets['physnet2']['bridge']}"

          if pnets['physnet-ironic']
            physnet_ironic = "physnet-ironic:#{pnets['physnet-ironic']['bridge']}"
          else
            physnet_ironic = []
          end

          physnets_array = [physnet2, physnet_ironic]
          bridge_mappings = physnets_array.compact

          it 'should declare neutron::agents::ml2::ovs with bridge_mappings' do
            should contain_class('neutron::agents::ml2::ovs').with(
              'bridge_mappings' => bridge_mappings
            )
          end
        end
      end
    end
  test_ubuntu_and_centos manifest
end

