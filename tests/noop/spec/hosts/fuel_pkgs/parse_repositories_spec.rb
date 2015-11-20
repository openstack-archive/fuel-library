require 'spec_helper'
require 'shared-examples'
manifest = 'fuel_pkgs/parse_repositories.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

