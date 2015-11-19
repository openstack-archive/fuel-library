require 'spec_helper'
require 'shared-examples'
manifest = 'master/nailgun-only.pp'

describe manifest do
  test_ubuntu_and_centos(manifest, true)
end

