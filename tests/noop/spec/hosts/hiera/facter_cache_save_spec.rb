require 'spec_helper'
require 'shared-examples'
manifest = 'hiera/facter_cache_save.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end
