require 'spec_helper'
require 'shared-examples'
manifest = 'openstack/network/neutron_agents.pp'

describe manifest do
  shared_examples 'catalog' do

    net_mtu = 9000

    if net_mtu
      physical_network_mtus = "physnet2:#{net_mtu}"
    else
      physical_network_mtus = ""
    end

    it 'should declare neutron::plugins::ml2 class' do
      should contain_class('neutron::plugins::ml2').with(
        'physical_network_mtus' => physical_network_mtus,
        'path_mtu'              => net_mtu,
      )
    end

  end
  test_ubuntu_and_centos manifest
end
