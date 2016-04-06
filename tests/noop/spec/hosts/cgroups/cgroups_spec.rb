# ROLE: virt
# ROLE: primary-mongo
# ROLE: primary-controller
# ROLE: mongo
# ROLE: ironic
# ROLE: controller
# ROLE: compute-vmware
# ROLE: compute
# ROLE: cinder-vmware
# ROLE: cinder-block-device
# ROLE: cinder
# ROLE: ceph-osd
# ROLE: base-os
require 'spec_helper'
require 'shared-examples'
manifest = 'cgroups/cgroups.pp'

describe manifest do

  before(:each) do
    Noop.puppet_function_load :prepare_cgroups_hash
    MockFunction.new(:prepare_cgroups_hash) do |function|
      allow(function).to receive(:call).and_return({})
    end
  end

  shared_examples 'catalog' do
    cgroups_hash = Noop.hiera_structure('cgroups', nil)
    if cgroups_hash
      it 'should declare cgroups class correctly' do
        should contain_class('cgroups').with(
          'cgroups_set'  => {},
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end
