require 'spec_helper'
require 'shared-examples'
manifest = 'master/dhcp-default-range.pp'

describe manifest do
  test_centos manifest
end
