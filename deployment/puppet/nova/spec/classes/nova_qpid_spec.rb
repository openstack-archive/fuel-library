require 'spec_helper'

describe 'nova::qpid' do

  let :facts do
    {:puppetversion => '2.7'}
  end

  describe 'with defaults' do

    it 'should contain all of the default resources' do

      should contain_class('qpid::server').with(
        :service_ensure    => 'running',
        :port              => '5672'
      )

    end

    it 'should contain user' do

      should contain_qpid_user('guest').with(
        :password => 'guest',
        :file     => '/var/lib/qpidd/qpidd.sasldb',
        :realm    => 'OPENSTACK',
        :provider => 'saslpasswd2'
      )

    end

  end

  describe 'when disabled' do
    let :params do
      {
        :enabled  => false
      }
    end

    it 'should be disabled' do

      should_not contain_qpid_user('guest')
      should contain_class('qpid::server').with(
        :service_ensure    => 'stopped'
      )

    end
  end

end
