# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'astute/service_token_off.pp'

describe manifest do
  shared_examples 'catalog' do

    keystone_params  = Noop.hiera_structure 'keystone'

    if keystone_params['service_token_off']
      it 'should contain apache/mod_wsgi keystone service' do
        case facts[:osfamily]
          when 'Debian'
            service_name = 'apache2'
          when 'RedHat'
            service_name = 'httpd'
        end

        is_expected.to contain_service('httpd').with(
          :ensure     => 'running',
          :name       => service_name,
          :hasrestart => 'true',
          :restart    => 'sleep 30 && apachectl graceful || apachectl restart'
        )
      end

      it 'should remove admin_token option' do
        is_expected.to contain_keystone_config('DEFAULT/admin_token').with_ensure('absent')
      end

      it 'should contain exec of remove AdminTokenAuthMiddleware from pipelines' do
        case facts[:osfamily]
          when 'Debian'
            paste_ini = '/etc/keystone/keystone-paste.ini'
          when 'RedHat'
            paste_ini = '/usr/share/keystone/keystone-dist-paste.ini'
        end

        is_expected.to contain_exec('remove_admin_token_auth_middleware').with(
          :path    => ['/bin', '/usr/bin'],
          :command => "sed -i.dist 's/ admin_token_auth//' #{paste_ini}",
          :onlyif  => "fgrep -q ' admin_token_auth' #{paste_ini}",
        )
      end
    end

  end
  test_ubuntu_and_centos manifest
end
