require 'spec_helper'
require 'shared-examples'
require 'yaml'
manifest = 'master/astute.pp'

# HIERA: master
# FACTS: master_centos7

describe manifest do
  shared_examples 'catalog' do
    let(:fuel_settings) do
      YAML.load facts[:astute_settings_yaml]
    end

    it 'should declare fuel::astute class with correct parameters' do
      parameters = {
          :rabbitmq_host => fuel_settings['ADMIN_NETWORK']['ipaddress'],
          :rabbitmq_astute_user => fuel_settings['astute']['user'],
          :rabbitmq_astute_password => fuel_settings['astute']['password'],
      }
      is_expected.to contain_class('fuel::astute').with parameters
    end

    it 'should declare "astute" fuel::systemd service' do
      is_expected.to contain_fuel__systemd('astute')
    end
  end
  run_test manifest
end
