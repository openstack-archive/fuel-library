require 'spec_helper'

describe 'nova::rabbitmq' do

  let :facts do
    {:puppetversion => '2.7'}
  end

  describe 'with defaults' do
  
    it 'should contain all of the default resources' do
  
      should contain_class('rabbitmq::server').with(
        :service_ensure    => 'running',
        :port              => '5672',
        :delete_guest_user => false
      )
    
      should contain_rabbitmq_vhost('/').with(
        :provider => 'rabbitmqctl'
      )
    end

  end

  describe 'when a rabbitmq user is specified' do

    let :params do
      {
        :userid   => 'dan',
        :password => 'pass'
      }
    end

    it 'should contain user and permissions' do

      should contain_rabbitmq_user('dan').with(
        :admin    => true,
        :password => 'pass',
        :provider => 'rabbitmqctl'
      )
  
      should contain_rabbitmq_user_permissions('dan@/').with(
        :configure_permission => '.*',
        :write_permission     => '.*',
        :read_permission      => '.*',
        :provider             => 'rabbitmqctl'
      )

    end

  end

  describe 'when disabled' do
    let :params do
      {
        :userid   => 'dan',
        :password => 'pass',
        :enabled  => false
      }
    end

    it 'should be disabled' do

      should_not contain_rabbitmq_user('dan')
      should_not contain_rabbitmq_user_permissions('dan@/')
      should contain_class('rabbitmq::server').with(
        :service_ensure    => 'stopped',
        :port              => '5672',
        :delete_guest_user => false
      )
    
      should_not contain_rabbitmq_vhost('/')

    end
  end


end
