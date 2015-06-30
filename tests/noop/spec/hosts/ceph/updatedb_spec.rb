require 'spec_helper'
require 'shared-examples'
manifest = 'ceph/updatedb.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

