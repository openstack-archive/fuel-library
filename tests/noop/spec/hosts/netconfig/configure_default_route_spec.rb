require 'spec_helper'
require 'shared-examples'
manifest = 'netconfig/configure_default_route.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

