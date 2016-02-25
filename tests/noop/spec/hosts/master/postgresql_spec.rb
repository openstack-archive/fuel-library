require 'spec_helper'
require 'shared-examples'
require 'yaml'
manifest = 'master/postgresql.pp'

# HIERA: master
# FACTS: master_centos7

describe manifest do
  shared_examples 'catalog' do
    let(:fuel_settings) do
      YAML.load facts[:astute_settings_yaml]
    end

    it 'should declare "fuel::postgresql" class correctly' do
      parameters = {
          :nailgun_db_name      => fuel_settings['postgres']['nailgun_dbname'],
          :nailgun_db_user      => fuel_settings['postgres']['nailgun_user'],
          :nailgun_db_password  => fuel_settings['postgres']['nailgun_password'],
          :keystone_db_name     => fuel_settings['postgres']['keystone_dbname'],
          :keystone_db_user     => fuel_settings['postgres']['keystone_user'],
          :keystone_db_password => fuel_settings['postgres']['keystone_password'],
          :ostf_db_name         => fuel_settings['postgres']['ostf_dbname'],
          :ostf_db_user         => fuel_settings['postgres']['ostf_user'],
          :ostf_db_password     => fuel_settings['postgres']['ostf_password'],
      }
      is_expected.to contain_class('fuel::postgresql').with parameters
    end

  end
  run_test manifest
end
