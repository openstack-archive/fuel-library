require 'spec_helper'
require 'shared-examples'
manifest = 'master/dhcp-default-range.pp'

# HIERA: master
# FACTS: master_centos6 master_centos7

describe manifest do
  test_centos manifest
end
