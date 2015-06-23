require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-cinder/cinder_db.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

