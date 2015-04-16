require 'spec_helper'
require 'shared-examples'
manifest = 'rabbitmq/rabbitmq.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should have admin plugin enabled' do
      should contain_class('::rabbitmq').with(
        'admin_enabled' => true
      )
    end
  end
  test_ubuntu_and_centos manifest

end

