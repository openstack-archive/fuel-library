require 'spec_helper'
require 'shared-examples'
manifest = 'murano/rabbitmq.pp'

describe manifest do
  shared_examples 'rabbitmq' do

    let(:rabbit_user) { Noop.hiera_structure('rabbit/user', 'murano') }

    it 'should declare rabbitmq_vhost' do
      should contain_rabbitmq_vhost('/murano')
    end

    it 'should declare rabbitmq_user_permission' do
      should contain_rabbitmq_user_permissions("#{rabbit_user}@/murano").with({
        :configure_permission => '.*',
        :read_permission      => '.*',
        :write_permission     => '.*',
      })
    end
  end

  test_ubuntu_and_centos manifest
end
