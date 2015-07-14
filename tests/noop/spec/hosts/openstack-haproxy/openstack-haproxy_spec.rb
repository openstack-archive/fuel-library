require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-haproxy/openstack-haproxy.pp'

describe manifest do
  shared_examples 'catalog' do

    it "should delcare openstack::ha::haproxy_service" do
      should contain_openstack__ha__haproxy_service('stats')
    end
  end

  test_ubuntu_and_centos manifest
end

