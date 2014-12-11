require 'spec_helper'
require 'shared-examples'
manifest = 'ntp/ntp-client.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

