require 'spec_helper'
require 'shared-examples'
manifest = 'vmware/compute-vmware.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

