require 'spec_helper'
require 'shared-examples'
manifest = 'vmware/compute-vmware.pp'

describe manifest do
  shared_examples 'catalog' do

    it 'should have cache_prefix option set to $host' do
      should contain_file('/etc/nova/nova-compute.conf').with_content(
        %r{\n\s*cache_prefix=\$host\n}
      )
    end

    network_manager = Noop.hiera_structure('novanetwork_parameters/network_manager')

    if network_manager == 'VlanManager'
      it 'should have vlan_interface option set to vmnic0' do
        should contain_file('/etc/nova/nova-compute.conf').with_content(
          %r{\n\s*vlan_interface=vmnic0\n}
        )
      end
    end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
 end

