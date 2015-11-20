require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/networks.pp'

describe manifest do
  shared_examples 'catalog' do
    if (Noop.hiera('use_neutron') and Noop.hiera('primary_controller'))
      context 'with Neutron' do
        neutron_config = Noop.hiera('neutron_config')
        nets = neutron_config['predefined_networks']

        floating_net   = (neutron_config['default_floating_net'] or 'net04_ext')
        private_net    = (neutron_config['default_private_net'] or 'net04')
        default_router = (neutron_config['default_router'] or 'router04')

        context 'Private network', :if => nets.has_key?(private_net) do
          if nets[private_net]['L2']['segment_id']
            segment_id = nets[private_net]['L2']['segment_id']
          else
            if nets[private_net]['L2']['network_type'] == 'vlan'
              segment_id = neutron_config['L2']['phys_nets']['physnet2']['vlan_range'].split(':')[0]
            else
              segment_id = neutron_config['L2']['tunnel_id_ranges'].split(':')[0]
            end
          end
          it 'should create private network' do
            should contain_neutron_network(private_net).with(
              'ensure'                    => 'present',
              'provider_physical_network' => (nets[private_net]['L2']['physnet'] or false),
              'provider_network_type'     => nets[private_net]['L2']['network_type'],
              'provider_segmentation_id'  => segment_id,
              'router_external'           => nets[private_net]['L2']['router_ext'],
              'shared'                    => nets[private_net]['shared'],
            )
          end
          it 'should create subnet for private network' do
            should contain_neutron_subnet("#{private_net}__subnet").with(
              'ensure'          => 'present',
              'cidr'            => nets[private_net]['L3']['subnet'],
              'network_name'    => private_net,
              'gateway_ip'      => nets[private_net]['L3']['gateway'],
              'dns_nameservers' => nets[private_net]['L3']['nameservers'],
              'enable_dhcp'     => 'true',
            )
          end
        end

        context 'Floating network', :if => nets.has_key?(floating_net) do
          it 'should create network for floating' do
            should contain_neutron_network(floating_net).with(
              'ensure'                    => 'present',
              'provider_physical_network' => (nets[floating_net]['L2']['physnet'] or false),
              'provider_network_type'     => 'flat',
              'router_external'           => nets[floating_net]['L2']['router_ext'],
              'shared'                    => nets[floating_net]['shared'],
            )
          end
          floating_range = nets[floating_net]['L3']['floating']
          if floating_range
            floating_range = floating_range.split(':')
          end
          it 'should create subnet for floating' do
            should contain_neutron_subnet("#{floating_net}__subnet").with(
              'ensure'           => 'present',
              'cidr'             => nets[floating_net]['L3']['subnet'],
              'network_name'     => floating_net,
              'gateway_ip'       => nets[floating_net]['L3']['gateway'],
              'allocation_pools' => "start=#{floating_range[0]},end=#{floating_range[1]}",
              'enable_dhcp'      => 'false',
            )
          end
        end

        context 'Ironic baremetal network', :if => nets.has_key?('baremetal') do
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
          end
        end

      end
    end
  end
  test_ubuntu_and_centos manifest
end
