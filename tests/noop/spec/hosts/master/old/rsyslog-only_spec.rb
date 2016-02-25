require 'spec_helper'
require 'shared-examples'
manifest = 'master/rsyslog-only.pp'

describe manifest do
  test_centos manifest
end
