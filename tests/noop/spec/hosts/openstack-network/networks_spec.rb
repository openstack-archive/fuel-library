require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/networks.pp'

describe manifest do
  shared_examples 'catalog' do
    context 'with Neutron', :if => (Noop.hiera('use_neutron') and Noop.hiera('primary_controller')) do
      neutron_config = Noop.hiera('neutron_config')
      nets = neutron_config['predefined_networks']

      floating_net   = (neutron_config['default_floating_net'] or 'net04_ext')
      private_net    = (neutron_config['default_private_net'] or 'net04')
      default_router = (neutron_config['default_router'] or 'router04')

      if nets.has_key?(private_net)
        it 'should create private network' do
          should contain_neutron_network(private_net).with(
            'ensure'                    => 'present',
            'provider_physical_network' => (nets[private_net]['L2']['physnet'] or false),
            'provider_network_type'     => 'vxlan',
            #'provider_segmentation_id'  => nets[private_net]['L2']['segment_id'],
            'router_external'           => nets[private_net]['L2']['router_ext'],
            'shared'                    => nets[private_net]['shared'],
          )
        end
      end

      if nets.has_key?(floating_net)
        it 'should create network for floating' do
          should contain_neutron_network(floating_net).with(
            'ensure'                    => 'present',
            'provider_physical_network' => (nets[floating_net]['L2']['physnet'] or false),
            'provider_network_type'     => 'local',
            'router_external'           => nets[floating_net]['L2']['router_ext'],
            'shared'                    => nets[floating_net]['shared'],
          )
        end
  #  provider_physical_network => $floating_net_physnet,
  # provider_network_type     => 'local',
  # router_external           => $floating_net_router_external,
  # tenant_name               => $tenant_name,
  # shared                    => $floating_net_shared
     end

      context 'with Ironic networks', :if => nets.has_key?('baremetal') do
        it 'should create baremetal network' do
          should contain_neutron_network('baremetal').with(
            'ensure'                    => 'present',
            'provider_physical_network' => nets['baremetal']['L2']['physnet'],
            'provider_network_type'     => 'flat',
            'provider_segmentation_id'  => nets['baremetal']['L2']['segment_id'],
            'router_external'           => nets['baremetal']['L2']['router_ext'],
            'shared'                    => nets['baremetal']['shared'],
          )
        end
        it 'should create baremetal network_subnet' do
          should contain_neutron_subnet('baremetal__subnet').with(
            'ensure'          => 'present',
            'cidr'            => nets['baremetal']['L3']['subnet'],
            'network_name'    => 'baremetal',
            'gateway_ip'      => nets['baremetal']['L3']['gateway'],
            'enable_dhcp'     => 'true',
            'dns_nameservers' => nets['baremetal']['L3']['nameservers'],
          )
          should contain_neutron_subnet('baremetal__subnet').that_comes_before(
            'neutron_router_interface[router04:baremetal__subnet]'
          )
        end
      end
    end
  end #end of shared_examples
  test_ubuntu_and_centos manifest
end
