require 'spec_helper'

describe 'openstack::heat' do

  let :params do
    {
        :amqp_password => "rabbit_password",
    }
  end

  shared_examples_for 'heat configuration' do

    it 'contains openstack::heat' do
      should contain_class('openstack::heat')
    end

    it 'configures with the default params' do
      should contain_class('heat').with(
        :database_connection => 'mysql://heat:heat@localhost/heat'
      )
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian',
        :operatingsystem => 'Debian',
        :hostname => 'hostname.example.com',
        :physicalprocessorcount => 2,
        :memorysize_mb => 1024,
        :openstack_version => {'nova' => 'present' },
      }
    end

    it_configures 'heat configuration'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
        :operatingsystemrelease => '7.1',
        :operatingsystemmajrelease => '7',
        :hostname => 'hostname.example.com',
        :physicalprocessorcount => 2,
        :memorysize_mb => 1024,
        :openstack_version => {'nova' => 'present' },
      }
    end

    it_configures 'heat configuration'
  end

end
