require 'spec_helper'
require 'shared-examples'
manifest = 'astute/enable_cinder.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

