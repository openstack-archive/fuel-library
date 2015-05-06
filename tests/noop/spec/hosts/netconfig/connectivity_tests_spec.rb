require 'spec_helper'
require 'shared-examples'
manifest = 'netconfig/connectivity_tests.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

