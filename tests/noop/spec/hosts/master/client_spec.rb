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
      }
      is_expected.to contain_class('fuel::nailgun::client').with parameters
    end

    it 'should have exec "sync_deployment_tasks"' do
      is_expected.to contain_exec 'sync_deployment_tasks'
    end
  end
  run_test manifest
end
