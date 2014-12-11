require 'spec_helper'
require 'shared-examples'
manifest = 'roles/ceph-osd.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

