require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/plugins/ml2.pp'

describe manifest do
  shared_examples 'catalog' do
    if (Noop.hiera('use_neutron') and Noop.hiera('role') =~ /controller|compute/)

      let(:network_scheme) do
        Noop.hiera_hash('network_scheme', {})
      end

      let(:prepare) do
        Noop.puppet_function('prepare_network_config', network_scheme)
      end

      let(:bind_host) do
        prepare
        Noop.puppet_function('get_network_role_property', 'neutron/mesh', 'ipaddr')
      end

      context 'with Neutron-ml2-plugin' do

        role = Noop.hiera('role')
        neutron_config = Noop.hiera_hash('neutron_config')
        adv_neutron_config = Noop.hiera_hash('neutron_advanced_configuration')
        pnets = neutron_config.fetch('L2',{}).fetch('phys_nets',{})
        segmentation_type = neutron_config.fetch('L2',{}).fetch('segmentation_type')

        if segmentation_type == 'vlan'
          physnets_array = ["physnet2:#{pnets['physnet2']['bridge']}"]
          network_type   = 'vlan'
          network_vlan_ranges_physnet2 = pnets.fetch('physnet2',{}).fetch('vlan_range')
          network_vlan_ranges = ["physnet2:#{network_vlan_ranges_physnet2}"]
          tunnel_id_ranges  = []
          physical_network_mtus = ["physnet2:1500"]
          overlay_net_mtu = '1500'
          tunnel_types = []
        else
          physnets_array = []
          network_type   = 'vxlan'
          network_vlan_ranges = []
          tunnel_id_ranges  = [neutron_config.fetch('L2',{}).fetch('tunnel_id_ranges')]
          physical_network_mtus = []
          overlay_net_mtu = '1450'
          tunnel_types    = [network_type]
        end
        if pnets['physnet-ironic']
          physnets_array << "physnet-ironic:#{pnets['physnet-ironic']['bridge']}"
        end

        bridge_mappings = physnets_array.compact
        it { should contain_class('neutron::agents::ml2::ovs').with(
          'bridge_mappings' => bridge_mappings
        )}

        it { should contain_class('neutron::plugins::ml2').with(
          'enable_security_group' => 'true',
        )}
        it { should contain_class('neutron::plugins::ml2').with(
          'flat_networks' => '*',
        )}
        it { should contain_class('neutron::plugins::ml2').with(
          'type_drivers' => ['local', 'flat', 'vlan', 'gre', 'vxlan'],
        )}
        it { should contain_class('neutron::plugins::ml2').with(
          'tenant_network_types' => ['flat', network_type],
        )}
        it { should contain_class('neutron::plugins::ml2').with(
          'mechanism_drivers' => neutron_config.fetch('L2', {}).fetch('mechanism_drivers', 'openvswitch,l2population').split(',')
        )}
        it { should contain_class('neutron::plugins::ml2').with(
          'network_vlan_ranges' => network_vlan_ranges,
        )}
        it { should contain_class('neutron::plugins::ml2').with(
          'tunnel_id_ranges' => tunnel_id_ranges,
        )}
        it { should contain_class('neutron::plugins::ml2').with(
          'vni_ranges' => tunnel_id_ranges,
        )}
        it { should contain_class('neutron::plugins::ml2').with(
          'vxlan_group' => '224.0.0.1',
        )}
        it { should contain_class('neutron::plugins::ml2').with(
          'physical_network_mtus' => physical_network_mtus,
        )}
        it { should contain_class('neutron::plugins::ml2').with(
          'path_mtu' => overlay_net_mtu,
        )}

        it { should contain_class('neutron::agents::ml2::ovs').with(
          'enabled' => true,
        )}
        it { should contain_class('neutron::agents::ml2::ovs').with(
          'manage_service' => true,
        )}
        it { should contain_class('neutron::agents::ml2::ovs').with(
          'manage_vswitch' => false,
        )}
        it { should contain_class('neutron::agents::ml2::ovs').with(
          'l2_population' => adv_neutron_config.fetch('neutron_l2_pop', false)
        )}
        it { should contain_class('neutron::agents::ml2::ovs').with(
          'arp_responder' => adv_neutron_config.fetch('neutron_l2_pop', false)
        )}
        it { should contain_class('neutron::agents::ml2::ovs').with(
          'enable_distributed_routing' => adv_neutron_config.fetch('neutron_dvr', false)
        )}
        it { should contain_class('neutron::agents::ml2::ovs').with(
          'tunnel_types' => tunnel_types
        )}
        it {
          ip = bind_host
          should contain_class('neutron::agents::ml2::ovs').with(
          'local_ip' => (ip ? ip : 'false')
        )}
        it { should contain_class('neutron::agents::ml2::ovs').with(
          'enable_tunneling' => (segmentation_type != 'vlan')
        )}
        it { should contain_class('neutron::agents::ml2::ovs').with(
          'bridge_mappings' => bridge_mappings
        )}

        # check whether Neutron server started only on controllers
        if role =~ /controller/
          it { should contain_service('neutron-server').with(
            'ensure' => 'running',
            'enable' => 'true',
          )}
          it { should contain_exec('waiting-for-neutron-api') }
          it { should contain_service('neutron-server').that_comes_before(
            "Exec[waiting-for-neutron-api]"
          )}
          if adv_neutron_config.fetch('l2_agent_ha', true)
            it { should contain_class('cluster::neutron::ovs').with(
              'primary' => (role == 'primary-controller'),
            )}
          end
        elsif role == 'compute'
          it { should contain_service('neutron-server').with(
            'ensure' => 'stopped',
            'enable' => 'false',
          )}
        end
      end
    end
  end
  test_ubuntu_and_centos manifest
end


