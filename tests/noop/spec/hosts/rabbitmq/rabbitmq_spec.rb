require 'spec_helper'
require 'shared-examples'
manifest = 'rabbitmq/rabbitmq.pp'

describe manifest do
  shared_examples 'catalog' do

    it 'has correct SERVER_ERL_ARGS in environment_variables' do
      environment_variables = Noop.resource_parameter_value self, 'class', 'rabbitmq', 'environment_variables'
      expect(environment_variables['SERVER_ERL_ARGS']).to eq '"+K true +A48 +P 1048576"'
    end

    # LP#1477595
    it "should contain rabbitmq correct log levels" do
      debug = Noop.hiera('debug', false)
      if debug
        # FIXME(aschultz): debug wasn't introduced until v3.5.0, when we upgrade
        # we should change info to debug. Also, don't forget to fix the
        # provisioning code!
        log_levels = '[{connection,info}]'
      else
        log_levels = '[{connection,info}]'
      end
      should contain_class('rabbitmq').with_config_variables(/#{log_levels}/)
    end

    it "should configure rabbitmq management" do
      debug = Noop.hiera('debug', false)
      collect_statistics_interval = '[{collect_statistics_interval,30000}]'
      rates_mode = '[{rates_mode, none}]'
      should contain_class('rabbitmq').with_config_variables(/#{collect_statistics_interval}/)
      should contain_class('rabbitmq').with_config_rabbitmq_management_variables(/#{rates_mode}/)
    end

    # Partial LP#1493520
    it "should configure rabbitmq disk_free_limit" do
      disk_free_limit = '[{disk_free_limit,5000000}]'
      should contain_class('rabbitmq').with_config_variables(/#{disk_free_limit}/)
    end

    it "should start epmd before rabbitmq plugins" do
      should contain_exec('epmd_daemon').that_comes_before('Rabbitmq_plugin[rabbitmq_management]')
    end

    it "should override service on package install" do
      should contain_tweaks__ubuntu_service_override('rabbitmq-server')
    end
  end
  test_ubuntu_and_centos manifest
end
