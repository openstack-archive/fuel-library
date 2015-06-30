require 'spec_helper'
require 'shared-examples'
manifest = 'ceilometer/endpoint.pp'

describe manifest do 
  test_ubuntu_and_centos manifest
end
