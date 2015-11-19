require 'spec_helper'
require 'shared-examples'
manifest = 'master/dhcp-default-range.pp'

describe manifest do
  test_ubuntu_and_centos(manifest, true)
end
