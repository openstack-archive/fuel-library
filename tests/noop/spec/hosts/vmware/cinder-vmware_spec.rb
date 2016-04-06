# ROLE: cinder-vmware

require 'spec_helper'
require 'shared-examples'
manifest = 'vmware/cinder-vmware.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

