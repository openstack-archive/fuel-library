require 'spec_helper'
require 'shared-examples'
manifest = 'rabbitmq/rabbitmq.pp'

describe manifest do
  test_ubuntu_and_centos manifest

  it 'should have admin plugin enabled' do
      should contain_class('rabbitmq').with(
        'admin_enabled' => true
      )
  end
end

