require 'spec_helper'
require 'shared-examples'
manifest = 'dns/dns-server.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

