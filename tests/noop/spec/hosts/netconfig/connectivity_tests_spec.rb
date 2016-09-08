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

# DISABLE_SPEC
# TODO: fix url_available mock

require 'spec_helper'
require 'shared-examples'
manifest = 'netconfig/connectivity_tests.pp'

describe manifest do
  before(:each) {
    Puppet::Parser::Functions.newfunction(:url_available) { |args|
      return true
    }
  }
  test_ubuntu_and_centos manifest
end
