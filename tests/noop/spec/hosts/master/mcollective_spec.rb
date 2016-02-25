require 'spec_helper'
require 'shared-examples'
require 'yaml'
manifest = 'master/mcollective.pp'

# HIERA: master
# FACTS: master_centos7

describe manifest do
  shared_examples 'catalog' do
    let(:fuel_settings) do
      YAML.load facts[:astute_settings_yaml]
    end

    it 'should declare fuel::mcollective class correctly' do
      parameters = {
          :mco_host      => fuel_settings['ADMIN_NETWORK']['ipaddress'],
          :mco_user      => fuel_settings['mcollective']['user'],
          :mco_password  => fuel_settings['mcollective']['password'],
      }
      is_expected.to contain_class('fuel::mcollective').with parameters
    end
  end
  run_test manifest
end
