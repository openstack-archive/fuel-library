require 'spec_helper'
require 'shared-examples'
require 'yaml'
manifest = 'master/client.pp'

# HIERA: master
# FACTS: master_centos7

describe manifest do
  shared_examples 'catalog' do
    let(:fuel_settings) do
      YAML.load facts[:astute_settings_yaml]
    end

    it 'should declare "fuel::nailgun::client" with correct parameters' do
      parameters = {
          :server_address => fuel_settings['ADMIN_NETWORK']['ipaddress'],
          :keystone_user => fuel_settings['FUEL_ACCESS']['user'],
          :keystone_password => fuel_settings['FUEL_ACCESS']['password'],
          :keystone_tenant => fuel_settings['FUEL_ACCESS']['tenant'] || 'admin',
          :auth_url => "http://#{fuel_settings['ADMIN_NETWORK']['ipaddress']}:8000/keystone/v2.0",
      }
      is_expected.to contain_class('fuel::nailgun::client').with parameters
    end

    it 'should have exec "sync_deployment_tasks"' do
      is_expected.to contain_exec 'sync_deployment_tasks'
    end

    it 'should contain exec "sync_deployment_tasks"' do
      parameters = {
          :command   => 'fuel rel --sync-deployment-tasks --dir /etc/puppet/',
          :path      => '/usr/bin',
          :tries     => '12',
          :try_sleep => '10',
      }
      is_expected.to contain_exec('sync_deployment_tasks').with parameters

    end
  end
  run_test manifest
end
