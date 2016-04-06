# TODO: DEPRECATED
require 'spec_helper'
require 'shared-examples'
manifest = 'ntp/timesync.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

