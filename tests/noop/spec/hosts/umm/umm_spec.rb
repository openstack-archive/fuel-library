require 'spec_helper'
require 'shared-examples'
manifest = 'umm/umm.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

