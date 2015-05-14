require 'spec_helper'
require 'shared-examples'
manifest_create = 'keystone/workloads_collector.pp'
manifest_remove = 'keystone/remove_workloads_collector.pp'

describe manifest_create do
  test_ubuntu_and_centos manifest_create
end

describe manifest_remove do
  test_ubuntu_and_centos manifest_remove
end
