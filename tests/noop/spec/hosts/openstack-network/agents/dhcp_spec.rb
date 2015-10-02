require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/agents/dhcp.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

