require 'spec_helper'
require 'shared-examples'
require 'yaml'
manifest = 'master/rabbitmq.pp'

# HIERA: master
# FACTS: master_centos7

describe manifest do
  shared_examples 'catalog' do
    let(:fuel_settings) do
      YAML.load facts[:astute_settings_yaml]
    end

    it 'should declare "fuel::rabbitmq" class correctly' do
      parameters = {
          :astute_user => fuel_settings['astute']['user'],
          :astute_password => fuel_settings['astute']['password'],
          :bind_ip => fuel_settings['ADMIN_NETWORK']['ipaddress'],
          :mco_user => fuel_settings['mcollective']['user'],
          :mco_password => fuel_settings['mcollective']['password'],
          :env_config => {
              'RABBITMQ_SERVER_ERL_ARGS' => "+K true +P 1048576",
              'ERL_EPMD_ADDRESS' => fuel_settings['ADMIN_NETWORK']['ipaddress'],
              'NODENAME' => "rabbit@#{facts[:hostname]}",
          },
      }
      is_expected.to contain_class('fuel::rabbitmq').with parameters
    end

  end

  run_test manifest
end
