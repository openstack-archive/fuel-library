require 'spec_helper'
require 'shared-examples'
require 'yaml'
manifest = 'master/ostf.pp'

# HIERA: master
# FACTS: master_centos7

describe manifest do
  shared_examples 'catalog' do
    let(:fuel_settings) do
      YAML.load facts[:astute_settings_yaml]
    end

    it 'should declare "fuel::ostf" class correctly' do
      parameters = {
        :dbname             => fuel_settings['postgres']['ostf_dbname'],
        :dbuser             => fuel_settings['postgres']['ostf_user'],
        :dbpass             => fuel_settings['postgres']['ostf_password'],
        :dbhost             => fuel_settings['ADMIN_NETWORK']['ipaddress'],
        :nailgun_host       => fuel_settings['ADMIN_NETWORK']['ipaddress'],
        :host               => '0.0.0.0',
        :keystone_host      => fuel_settings['ADMIN_NETWORK']['ipaddress'],
        :keystone_ostf_user => fuel_settings['keystone']['ostf_user'],
        :keystone_ostf_pass => fuel_settings['keystone']['ostf_password'],
      }
      is_expected.to contain_class('fuel::ostf').with parameters
    end

    it 'should have "ostf" fuel::systemd service' do
      is_expected.to contain_fuel__systemd 'ostf'
    end

  end
  run_test manifest
end
