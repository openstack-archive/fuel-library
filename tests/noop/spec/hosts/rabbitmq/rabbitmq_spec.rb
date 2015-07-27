require 'spec_helper'
require 'shared-examples'
manifest = 'rabbitmq/rabbitmq.pp'

describe manifest do
  shared_examples 'catalog' do
    # LP#1477595
    it "should contain rabbitmq correct log levels" do
      debug = Noop.hiera('debug', false)
      if debug
        log_levels = '[{connection,debug}]'
      else
        log_levels = '[{connection,info}]'
      end
      should contain_class('rabbitmq').with_config_variables(/#{log_levels}/)
    end
  end
  test_ubuntu_and_centos manifest
end

