require 'spec_helper'
require 'shared-examples'
manifest = 'astute/dump_rabbitmq_definitions.pp'

describe manifest do
  shared_examples 'catalog' do
    it "should contain rabbitmq dump definitions exec" do
      should contain_exec('rabbitmq-dump-definitions')
    end
  end
  test_ubuntu_and_centos manifest
end
