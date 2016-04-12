# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'memcached/memcached.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

