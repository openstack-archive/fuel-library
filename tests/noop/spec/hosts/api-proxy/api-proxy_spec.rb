require 'spec_helper'
require 'shared-examples'
manifest = 'api-proxy/api-proxy.pp'

describe manifest do
  shared_examples 'catalog' do
    it {
      should contain_service('httpd').with(
           'hasrestart' => true,
           'restart'    => 'apachectl graceful || apachectl restart'
      )
    }
  end
  test_ubuntu_and_centos manifest
end

