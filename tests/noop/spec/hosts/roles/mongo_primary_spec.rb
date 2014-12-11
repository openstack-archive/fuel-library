require 'spec_helper'
require 'shared-examples'
manifest = 'roles/mongo_primary.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

