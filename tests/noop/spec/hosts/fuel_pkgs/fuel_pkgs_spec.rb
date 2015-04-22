require 'spec_helper'
require 'shared-examples'
manifest = 'fuel_pkgs/fuel_pkgs.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

