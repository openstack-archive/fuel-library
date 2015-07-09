require 'spec_helper'
require 'shared-examples'
manifest = 'roles/compute.pp'

describe manifest do
  shared_examples 'catalog' do

   it 'should declare class nova::compute with install_bridge_utils set to false' do
      should contain_class('nova::compute').with(
        'install_bridge_utils' => false,
      )
    end

    it 'should configure libvirt_inject_partition for compute node' do
      # Related-bug #1472520
      libvirt_inject_partition = '-2'
      should contain_class('nova::compute::libvirt').with(
        'libvirt_inject_partition' => libvirt_inject_partition,
      )
    end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end
