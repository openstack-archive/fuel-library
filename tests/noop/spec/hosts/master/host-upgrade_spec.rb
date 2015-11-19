require 'spec_helper'
require 'shared-examples'
manifest = 'master/host-upgrade.pp'

describe manifest do
  test_centos manifest
end
