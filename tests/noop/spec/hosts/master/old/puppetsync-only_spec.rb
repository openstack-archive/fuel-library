require 'spec_helper'
require 'shared-examples'
manifest = 'master/puppetsync-only.pp'

describe manifest do
  test_centos manifest
end
