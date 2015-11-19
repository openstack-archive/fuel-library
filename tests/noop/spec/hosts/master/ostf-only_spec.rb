require 'spec_helper'
require 'shared-examples'
manifest = 'master/ostf-only.pp'

describe manifest do
  test_centos manifest
end
