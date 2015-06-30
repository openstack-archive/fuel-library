require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-controller/openstack-controller-endpoint.pp'

describe manifest do 
  test_ubuntu_and_centos manifest
end
