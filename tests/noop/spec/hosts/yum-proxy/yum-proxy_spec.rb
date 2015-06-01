require 'spec_helper'
require 'shared-examples'
manifest = 'yum-proxy/yum-proxy.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

