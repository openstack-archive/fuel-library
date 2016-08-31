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
manifest = 'netconfig/connectivity_tests.pp'

describe manifest do
  before(:each) {
    Puppet::Parser::Functions.newfunction(:url_available) { |args|
      return true
    }
  }
  shared_examples 'catalog' do
    it { should contain_ping_host(default_gateway.join()).with('ensure' => 'up') }
  end
  test_ubuntu_and_centos manifest
end
