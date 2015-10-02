require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/nova.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

