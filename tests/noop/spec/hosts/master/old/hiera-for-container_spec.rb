require 'spec_helper'
require 'shared-examples'
manifest = 'master/hiera-for-container.pp'

describe manifest do
  test_centos manifest
end
