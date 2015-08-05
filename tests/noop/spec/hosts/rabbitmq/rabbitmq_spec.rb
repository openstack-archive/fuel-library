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
      expect(environment_variables['SERVER_ERL_ARGS']).to eq '"+K true +A48 +P 1048576"'
    end

  end
  test_ubuntu_and_centos manifest
end
