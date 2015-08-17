require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-haproxy/openstack-haproxy-keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    options = {
      'option'  => ['httpchk', 'httplog', 'httpclose'],
      'timeout' => ['connect 1m', 'http-request 1m']
    }
    it "should contain 1m connect timeout" do
      should contain_openstack__ha__haproxy_service('keystone-1').with(
        'haproxy_config_options' => options
      )
      should contain_openstack__ha__haproxy_service('keystone-2').with(
        'haproxy_config_options' => options
      )
    end
  end

  test_ubuntu_and_centos manifest
end

