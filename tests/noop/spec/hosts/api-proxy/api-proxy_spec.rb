require 'spec_helper'
require 'shared-examples'
manifest = 'api-proxy/api-proxy.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

