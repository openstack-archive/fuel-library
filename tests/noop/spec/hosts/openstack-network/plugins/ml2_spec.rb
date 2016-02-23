require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/plugins/ml2.pp'

describe manifest do

  before(:each) do
    Noop.puppet_function_load :is_pkg_installed
    MockFunction.new(:is_pkg_installed) do |function|
      allow(function).to receive(:call).and_return false
    end
  end

  shared_examples 'catalog' do
    if (Noop.hiera('use_neutron') and Noop.hiera('role') =~ /controller|compute|ironic/)

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

      let(:configuration_override) do
        Noop.hiera_structure 'configuration'
      end

      let(:neutron_agent_ovs_override_resources) do
        configuration_override.fetch('neutron_agent_ovs', {})
      end

      context 'with Neutron-ml2-plugin' do

        role = Noop.hiera('role')
        neutron_config = Noop.hiera_hash('neutron_config')
        adv_neutron_config = Noop.hiera_hash('neutron_advanced_configuration')
        dvr = adv_neutron_config.fetch('neutron_dvr', false)
        pnets = neutron_config.fetch('L2',{}).fetch('phys_nets',{})
        segmentation_type = neutron_config.fetch('L2',{}).fetch('segmentation_type')
        l2_population = adv_neutron_config.fetch('neutron_l2_pop', false)
        dpdk_config = Noop.hiera_hash('dpdk', {})
        enable_dpdk = dpdk_config.fetch('enabled', false)

        if segmentation_type == 'vlan'
          network_type   = 'vlan'
          if role =~ /controller/ and !dvr
            physnets_array = ["physnet1:#{pnets['physnet1']['bridge']}", "physnet2:#{pnets['physnet2']['bridge']}"]
          else
            physnets_array = ["physnet2:#{pnets['physnet2']['bridge']}"]
          end
          tunnel_id_ranges  = []
          tunnel_types = []
          if pnets['physnet-ironic']
            physnets_array << "physnet-ironic:#{pnets['physnet-ironic']['bridge']}"
          end
        else
          if role == 'compute' and !dvr
            physnets_array = []
          else
            physnets_array = ["physnet1:#{pnets['physnet1']['bridge']}"]
          end
          network_type   = 'vxlan'
          tunnel_types    = [network_type]
        end

       if role == 'compute' and enable_dpdk
         it 'should set dpdk-specific options for OVS agent' do
           should contain_neutron_plugin_ml2('ovs/datapath_type').with_value('netdev')
           should contain_neutron_plugin_ml2('ovs/vhostuser_socket_dir').with_value('/var/run/openvswitch')
         end
       end

        bridge_mappings = physnets_array.compact
        it { should contain_class('neutron::agents::ml2::ovs').with(
          'bridge_mappings' => bridge_mappings
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
          'l2_population' => l2_population
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
          if segmentation_type == 'vlan'
            ip = false
          else
            ip = bind_host
            ip = (ip ? ip : 'false')
          end
          should contain_class('neutron::agents::ml2::ovs').with(
          'local_ip' => ip
        )}
        it { should contain_class('neutron::agents::ml2::ovs').with(
          'enable_tunneling' => (segmentation_type != 'vlan')
        )}

        it 'neutron agent ovs should be modified by override_resources' do
          is_expected.to contain_override_resources('neutron_agent_ovs').with(:data => neutron_agent_ovs_override_resources)
        end

        it 'should use "override_resources" to update the catalog' do
          ral_catalog = Noop.create_ral_catalog self
          neutron_agent_ovs_override_resources.each do |title, params|
            params['value'] = 'True' if params['value'].is_a? TrueClass
            expect(ral_catalog).to contain_neutron_agent_ovs(title).with(params)
          end
        end

        # check whether Neutron server started only on controllers
        if role =~ /controller/
          it { should contain_service('neutron-server').with(
            'ensure' => 'running',
            'enable' => 'true',
          )}
          it { should contain_exec('waiting-for-neutron-api').with(
            'refreshonly' => 'true'
          )}
          it { should contain_exec('waiting-for-neutron-api').that_subscribes_to(
            'Service[neutron-server]'
          )}
          it { should contain_service('neutron-server') }
          if adv_neutron_config.fetch('l2_agent_ha', true)
            it { should contain_class('cluster::neutron::ovs').with(
              'primary' => (role == 'primary-controller'),
            )}
          end
        elsif role == 'compute'
          it { should_not contain_service('neutron-server') }
        elsif role == 'ironic'
          it { should_not contain_service('neutron-server') }
        end
      end
    end
  end
  test_ubuntu_and_centos manifest
end


