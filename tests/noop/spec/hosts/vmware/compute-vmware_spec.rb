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

    network_manager = task.hiera_structure('novanetwork_parameters/network_manager')

    if network_manager == 'VlanManager'
      it 'should have vlan_interface option set to vmnic0' do
        should contain_file('/etc/nova/nova-compute.conf').with_content(
          %r{\n\s*vlan_interface=vmnic0\n}
        )
      end
    end

    ceilometer_enabled = task.hiera_structure('ceilometer/enabled')

    if ceilometer_enabled == 'true'
      it 'should have /etc/ceilometer/ceilometer.conf' do
        should contain_file('/etc/ceilometer/ceilometer.conf').with_content(
          %r{\n\s*hypervisor_inspector=vsphere\n}
        )
      end
    end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
 end

