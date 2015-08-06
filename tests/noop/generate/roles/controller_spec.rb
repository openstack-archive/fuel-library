require 'spec_helper'
require 'shared-examples'
manifest = 'roles/controller.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

