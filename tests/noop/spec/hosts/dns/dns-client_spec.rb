require 'spec_helper'
require 'shared-examples'
manifest = 'dns/dns-client.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

