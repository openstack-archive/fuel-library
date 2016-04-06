# ROLE: virt
# ROLE: primary-mongo
# ROLE: primary-controller
# ROLE: mongo
# ROLE: ironic
# ROLE: controller
# ROLE: compute
# ROLE: cinder-vmware
# ROLE: cinder-block-device
# ROLE: cinder
# ROLE: ceph-osd
require 'spec_helper'
require 'shared-examples'
manifest = 'netconfig/reserved_ports.pp'
describe manifest do
  shared_examples 'catalog' do

    it { should contain_class('openstack::reserved_ports') }
  end

  test_ubuntu_and_centos manifest
end

