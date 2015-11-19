require 'spec_helper'
require 'shared-examples'
manifest = 'master/cobbler-only.pp'

describe manifest do
  test_ubuntu_and_centos(manifest, true)
end

