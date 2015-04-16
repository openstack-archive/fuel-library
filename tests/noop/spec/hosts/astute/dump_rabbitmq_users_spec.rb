require 'spec_helper'
require 'shared-examples'
manifest = 'astute/dump_rabbitmq_users.pp'

describe manifest do
  shared_examples 'catalog' do
    it "should contain rabbitmq dump users exec" do
      should contain_exec('rabbitmq-dump-users')
    end
  end
  test_ubuntu_and_centos manifest
end
