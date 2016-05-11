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
          :admin_token       => fuel_settings['keystone']['admin_token'],
          :host              => fuel_settings['ADMIN_NETWORK']['ipaddress'],
          :db_host           => fuel_settings['ADMIN_NETWORK']['ipaddress'],
          :db_name           => fuel_settings['postgres']['keystone_dbname'],
          :db_user           => fuel_settings['postgres']['keystone_user'],
          :db_password       => fuel_settings['postgres']['keystone_password'],
          :admin_password    => fuel_settings['FUEL_ACCESS']['password'],
          :monitord_user     => fuel_settings['keystone']['monitord_user'],
          :monitord_password => fuel_settings['keystone']['monitord_password'],
          :nailgun_user      => fuel_settings['keystone']['nailgun_user'],
          :nailgun_password  => fuel_settings['keystone']['nailgun_password'],
          :ostf_user         => fuel_settings['keystone']['ostf_user'],
          :ostf_password     => fuel_settings['keystone']['ostf_password'],
          :public_workers    => '5',
          :admin_workers     => '5',
      }
      is_expected.to contain_class('fuel::keystone').with parameters
    end

    it 'should have "openstack-keystone" fuel::systemd service' do
      parameters = {
          :start => true,
          :template_path => 'fuel/systemd/restart_template.erb',
          :config_name => 'restart.conf',
      }
      is_expected.to contain_fuel__systemd('openstack-keystone').with parameters
    end

  end
  run_test manifest
end
