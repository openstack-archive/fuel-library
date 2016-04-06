# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'vmware/vcenter.pp'

describe manifest do
  shared_examples 'catalog' do

    network_manager = Noop.hiera_structure('novanetwork_parameters/network_manager')

    if network_manager == 'VlanManager'
      it 'should declare vmware::controller with vlan_interface option set to vmnic0' do
        should contain_class('vmware::controller').with(
          'vlan_interface' => 'vmnic0',
        )
      end
    end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
 end

