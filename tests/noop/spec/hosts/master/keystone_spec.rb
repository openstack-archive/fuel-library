require 'spec_helper'
require 'shared-examples'
require 'yaml'
manifest = 'master/keystone.pp'

# HIERA: master
# FACTS: master_centos7

describe manifest do
  shared_examples 'catalog' do
    let(:fuel_settings) do
      YAML.load facts[:astute_settings_yaml]
    end

    it 'should declare "fuel::keystone" class correctly' do
      parameters = {
          :admin_token => fuel_settings['keystone']['admin_token'],
          :host => fuel_settings['ADMIN_NETWORK']['ipaddress'],
          :db_host => fuel_settings['ADMIN_NETWORK']['ipaddress'],
          :db_name => fuel_settings['postgres']['keystone_dbname'],
          :db_user => fuel_settings['postgres']['keystone_user'],
          :db_password => fuel_settings['postgres']['keystone_password'],
          :admin_password => fuel_settings['FUEL_ACCESS']['password'],
          :monitord_user => fuel_settings['keystone']['monitord_user'],
          :monitord_password => fuel_settings['keystone']['monitord_password'],
          :nailgun_user => fuel_settings['keystone']['nailgun_user'],
          :nailgun_password => fuel_settings['keystone']['nailgun_password'],
          :ostf_user => fuel_settings['keystone']['ostf_user'],
          :ostf_password => fuel_settings['keystone']['ostf_password'],
      }
      is_expected.to contain_class('fuel::keystone').with parameters
    end

    it {
      should contain_service('httpd').with(
           'hasrestart' => true,
           'restart'    => 'sleep 30 && apachectl graceful || apachectl restart'
      )
    }

  end
  run_test manifest
end
