# HIERA: master
# FACTS: master_centos7

require 'spec_helper'
require 'shared-examples'
manifest = 'master/keystone_token_disable.pp'

describe manifest do
  shared_examples 'catalog' do

    keystone_params  = Noop.hiera_structure 'keystone'
    disable_token = Noop.puppet_function('str2bool', keystone_params['service_token_off'])

    if disable_token
      it 'should remove admin_token option' do
        is_expected.to contain_keystone_config('DEFAULT/admin_token').with_ensure('absent')
      end

      it 'should contain exec of remove AdminTokenAuthMiddleware from pipelines' do
        paste_ini = '/etc/keystone/keystone-paste.ini'
        is_expected.to contain_exec('remove_admin_token_auth_middleware').with(
          :path    => ['/bin', '/usr/bin'],
          :command => "sed -i.dist 's/ admin_token_auth//' #{paste_ini}",
          :onlyif  => "fgrep -q ' admin_token_auth' #{paste_ini}",
        )
      end
    end
  end
  run_test manifest
end
