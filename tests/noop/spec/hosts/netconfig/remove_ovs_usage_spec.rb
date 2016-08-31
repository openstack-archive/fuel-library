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
manifest = 'netconfig/remove_ovs_usage.pp'
describe manifest do
  shared_examples 'catalog' do
    it { should contain_file('/etc/hiera/override/configuration/remove_ovs_usage.yaml') }
  end
  test_ubuntu_and_centos manifest
end
