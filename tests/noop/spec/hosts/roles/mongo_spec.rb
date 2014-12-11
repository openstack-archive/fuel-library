require 'spec_helper'
require 'shared-examples'
manifest = 'roles/mongo.pp'

describe manifest do
  shared_examples 'puppet catalogue' do
    it {
      File.stubs(:exists?).with('/var/lib/astute/mongodb/mongodb.key').returns(true)
      File.stubs(:exists?).returns(false)
      should compile
    }
  end
  test_ubuntu_and_centos manifest
end

