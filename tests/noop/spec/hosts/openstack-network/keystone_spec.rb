require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/keystone.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end
