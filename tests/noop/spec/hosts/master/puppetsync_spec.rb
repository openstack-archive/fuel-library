require 'spec_helper'
require 'shared-examples'
require 'yaml'
manifest = 'master/puppetsync.pp'

# HIERA: master
# FACTS: master_centos7

describe manifest do
  shared_examples 'catalog' do
    let(:fuel_settings) do
      YAML.load facts[:astute_settings_yaml]
    end

    it 'should contain class "fuel::puppetsync" with parameters' do
      is_expected.to contain_class('fuel::puppetsync').with(
          :bind_address => fuel_settings['ADMIN_NETWORK']['ipaddress'],
      )
    end

    it 'should contain "rsyncd" fuel::systemd service with parameters' do
      parameters = {
          :start => true,
          :template_path => 'fuel/systemd/restart_template.erb',
          :config_name => 'restart.conf',
      }
      is_expected.to contain_fuel__systemd('rsyncd').with parameters
    end
  end
  run_test manifest
end
