require 'spec_helper'
require 'shared-examples'
manifest = 'master/host-upgrade.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end
