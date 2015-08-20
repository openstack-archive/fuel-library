require 'spec_helper'
require 'shared-examples'
manifest = 'astute/service_token_off.pp'

describe manifest do
  shared_examples 'catalog' do

    it "should contain apache/mod_wsgi keystone service" do
      case facts[:osfamily]
      when 'Debian'
        service_name = 'apache2'
      when 'RedHat'
        service_name = 'httpd'
      end

      should contain_service('httpd').with({
         'ensure' => 'running',
         'name'   => service_name,
         })
    end

    it 'should remove admin_token option' do
      is_expected.to contain_keystone_config('DEFAULT/admin_token').with_ensure('absent')
    end

  end
  test_ubuntu_and_centos manifest
end
