require 'spec_helper'
require 'shared-examples'
manifest = 'master/dhcp-ranges.pp'

# HIERA: master
# FACTS: master_centos7
# DISABLE_SPEC

describe manifest do
  run_test manifest
end
