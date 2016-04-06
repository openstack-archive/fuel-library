# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'ntp/ntp-check.pp'

describe manifest do
  before(:each) {
    Puppet::Parser::Functions.newfunction(:ntp_available) { |args|
      return true
    }
  }
  test_ubuntu_and_centos manifest
end
