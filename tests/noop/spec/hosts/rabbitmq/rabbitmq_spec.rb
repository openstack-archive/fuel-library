require 'spec_helper'
require 'shared-examples'
manifest = 'rabbitmq/rabbitmq.pp'

describe manifest do
  shared_examples 'catalog' do
    def resource_parameter_value(resource_type, resource_name, parameter)
      catalog = subject
      catalog = subject.call if subject.is_a? Proc
      resource = catalog.resource resource_type, resource_name
      raise "No resource type: '#{resource_type}' name: '#{resource_name}' in catalog!" unless resource
      resource[parameter.to_sym]
    end

    it 'has correct SERVER_ERL_ARGS in environment_variables' do
      environment_variables = resource_parameter_value 'class', 'rabbitmq', 'environment_variables'
      expect(environment_variables['SERVER_ERL_ARGS']).to eq '"+K true +P 1048576"'
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
  end
  test_ubuntu_and_centos manifest
end
