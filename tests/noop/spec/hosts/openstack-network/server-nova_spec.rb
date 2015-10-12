require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/server-nova.pp'

describe manifest do
  shared_examples 'catalog' do

    use_neutron = Noop.hiera 'use_neutron', false

    if !use_neutron
      num_networks = Noop.hiera 'num_networks'
      nameservers  = Noop.hiera 'dns_nameservers'
      fixed_range  = Noop.hiera 'fixed_network_range'
      network_size = Noop.hiera 'network_size'

      if nameservers
        if nameservers.size >= 2
          dns_opts = "--dns1 #{nameservers[0]} --dns2 #{nameservers[1]}"
        else
          dns_opts = "--dns1 #{nameservers[0]}"
        end
      else
        dns_opts = ""
      end

      primary_controller = Noop.hiera 'primary_controller'
      if primary_controller
        it 'should create private nova network' do
          should contain_exec('create_private_nova_network').with(
            'command' => "nova-manage network create novanetwork #{fixed_range} #{num_networks} #{network_size} #{dns_opts}"
          )
        end
      end
    end

  end
  test_ubuntu_and_centos manifest
end

