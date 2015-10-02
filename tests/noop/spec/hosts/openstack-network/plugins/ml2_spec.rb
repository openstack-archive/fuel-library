require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/plugins/ml2.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

