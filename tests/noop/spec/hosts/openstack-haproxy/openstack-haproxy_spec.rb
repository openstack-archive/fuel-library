require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-haproxy/openstack-haproxy.pp'

describe manifest do
  shared_examples 'catalog' do
  test_ubuntu_and_centos manifest
end

