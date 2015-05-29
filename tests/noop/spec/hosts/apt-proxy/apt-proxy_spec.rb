require 'spec_helper'
require 'shared-examples'
manifest = 'apt-proxy/apt-proxy.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

