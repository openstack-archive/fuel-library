# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-haproxy/openstack-haproxy-glance.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

