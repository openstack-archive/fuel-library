require 'spec_helper'
require 'shared-examples'
manifest = 'astute/ceph_compute.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end
