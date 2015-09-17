require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/networks.pp'

describe manifest do
  shared_examples 'catalog' do
    if Noop.hiera('use_neutron')
      neutron_config = Noop.hiera 'neutron_config'
      nets = neutron_config['predefined_networks']

      if Noop.hiera 'primary_controller' and nets.has_key?('baremetal')
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
