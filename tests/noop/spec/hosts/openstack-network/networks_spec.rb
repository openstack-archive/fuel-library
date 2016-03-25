# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-controller.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-compute.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-cinder.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-mongo.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-controller.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-controller.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-compute.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-ceph-osd.yaml ubuntu
# RUN: neut_vlan.ironic.controller.yaml ubuntu
# RUN: neut_vlan.ironic.conductor.yaml ubuntu
# RUN: neut_vlan.compute.ssl.yaml ubuntu
# RUN: neut_vlan.compute.ssl.overridden.yaml ubuntu
# RUN: neut_vlan.compute.nossl.yaml ubuntu
# RUN: neut_vlan.cinder-block-device.compute.yaml ubuntu
# RUN: neut_vlan.ceph.controller-ephemeral-ceph.yaml ubuntu
# RUN: neut_vlan.ceph.compute-ephemeral-ceph.yaml ubuntu
# RUN: neut_vlan.ceph.ceil-primary-controller.overridden_ssl.yaml ubuntu
# RUN: neut_vlan.ceph.ceil-compute.overridden_ssl.yaml ubuntu
# RUN: neut_gre.generate_vms.yaml ubuntu
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
          case neutron_config['L2']['segmentation_type']
          when 'vlan'
            network_type = 'vlan'
          when 'gre'
            network_type = 'gre'
          else
            network_type = 'vxlan'
          end
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
              'provider_network_type'     => network_type,
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
          if floating_range and !floating_range.empty?
            if floating_range.is_a?(Array)
              # floating_range is array but we don't support more than one range
              # so we just take first element
              floating_range = floating_range[0].split(':')
            else
              # TODO: (adidenko) remove this condition when we update all fixtures
              # in old astute.yaml fixtures floating_range is a string
              # but in 8.0+ it's always array
              floating_range = floating_range.split(':')
            end
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
          let(:baremetal_allocation_pools) do
            Noop.puppet_function 'format_allocation_pools', nets['baremetal']['L3']['floating']
          end
          it 'should create baremetal network_subnet' do
            should contain_neutron_subnet('baremetal__subnet').with(
              'ensure'           => 'present',
              'cidr'             => nets['baremetal']['L3']['subnet'],
              'network_name'     => 'baremetal',
              'gateway_ip'       => nets['baremetal']['L3']['gateway'],
              'enable_dhcp'      => 'true',
              'dns_nameservers'  => nets['baremetal']['L3']['nameservers'],
              'allocation_pools' => baremetal_allocation_pools,
            )
          end
        end

      end
    end
  end
  test_ubuntu_and_centos manifest
end
