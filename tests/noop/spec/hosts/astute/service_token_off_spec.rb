require 'spec_helper'
require 'shared-examples'
manifest = 'astute/service_token_off.pp'

describe manifest do
  shared_examples 'catalog' do

    it 'should contain apache/mod_wsgi keystone service' do
      case facts[:osfamily]
        when 'Debian'
          service_name = 'apache2'
          paste_ini    = '/etc/keystone/keystone-paste.ini'
        when 'RedHat'
          service_name = 'httpd'
          paste_ini    = '/usr/share/keystone/keystone-dist-paste.ini'
      end

      should contain_service('httpd').with({
        'ensure'     => 'running',
        'name'       => service_name,
        'hasrestart' => 'true',
        'restart'    => 'apachectl graceful',
        })
    end

    it 'should remove admin_token option' do
      is_expected.to contain_keystone_config('DEFAULT/admin_token').with_ensure('absent')
    end

    it 'should contain exec of remove AdminTokenAuthMiddleware from pipelines' do
      should contain_exec('remove_admin_token_auth_middleware').with(
        :command => "sed -i.dist 's/ admin_token_auth//' #{paste_ini}",
        :onlyif  => "fgrep -q ' admin_token_auth' #{paste_ini}",
      )
    end

  end
  test_ubuntu_and_centos manifest
end
