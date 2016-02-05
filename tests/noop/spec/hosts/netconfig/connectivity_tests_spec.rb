require 'spec_helper'
require 'shared-examples'
manifest = 'netconfig/connectivity_tests.pp'

# HIERA: neut_vlan.ceph.controller-ephemeral-ceph
# FACTS: ubuntu

describe manifest do
  before(:each) {
    Puppet::Parser::Functions.newfunction(:url_available) { |args|
      return true
    }
  }
  test_ubuntu_and_centos manifest
end
