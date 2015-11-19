require 'spec_helper'
require 'shared-examples'
manifest = 'master/hiera-for-container.pp'

describe manifest do
  test_ubuntu_and_centos(manifest, true)
end

