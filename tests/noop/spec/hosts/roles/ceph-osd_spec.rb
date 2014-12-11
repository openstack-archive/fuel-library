require 'spec_helper'
require 'shared-examples'
manifest = 'roles/ceph-osd.pp'

describe manifest do

  shared_examples 'puppet catalogue' do
    # Test that catalog compiles and there are no dependency cycles in the graph
    it {
      File.stubs(:exists?).with('/var/lib/astute/ceph/ceph').returns(true)
      File.stubs(:exists?).returns(false)
    }
  end

  test_ubuntu_and_centos manifest
end

