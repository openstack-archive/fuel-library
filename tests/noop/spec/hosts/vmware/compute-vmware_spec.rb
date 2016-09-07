# ROLE: compute-vmware

require 'spec_helper'
require 'shared-examples'
manifest = 'vmware/compute-vmware.pp'

describe manifest do
  shared_examples 'catalog' do

    network_manager = Noop.hiera_structure('novanetwork_parameters/network_manager')
    ceilometer_enabled = Noop.hiera_structure('ceilometer/enabled')
    computes = Noop.hiera_structure('vcenter/computes', [])

    it 'should have force_config_drive option set to False' do
      is_expected.to contain_nova_compute_config('DEFAULT/force_config_drive').with_value(false)
    end

    if ceilometer_enabled and computes.any?

      it 'should have cache_prefix option set to $host' do
        is_expected.to contain_nova_compute_config('vmware/cache_prefix').with_value('$host')
      end

      if network_manager == 'VlanManager'
        it 'should have vlan_interface option set to vmnic0' do
          is_expected.to contain_nova_compute_config('vmware/vlan_interface').with_value('vmnic0')
        end
      end

      it 'should have /etc/ceilometer/ceilometer.conf' do
        should contain_file('/etc/ceilometer/ceilometer.conf').with_content(%r{\n\s*hypervisor_inspector=vsphere\n})
      end

    end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

