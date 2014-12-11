require 'spec_helper'
require 'shared-examples'
manifest = 'virtual_ips/virtual_ips.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

