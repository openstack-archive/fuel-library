require 'spec_helper'
require 'shared-examples'
manifest = 'murano/murano_db.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

