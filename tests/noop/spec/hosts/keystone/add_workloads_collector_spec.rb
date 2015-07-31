require 'spec_helper'
require 'shared-examples'
manifest = 'keystone/add_workloads_collector.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end
