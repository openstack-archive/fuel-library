require 'spec_helper'

describe 'openstack::nova::controller' do

  let :params do
    {
      :keystone_identity_uri => 'https://192.168.10.1:35357/',
      :keystone_auth_uri => 'https://192.168.10.1:5000/',
      :admin_address => '192.168.10.0',
      :db_host => '192.168.10.0',
      :internal_address => '192.168.10.0',
      :public_address => '192.168.10.0',
      :nova_db_password => 'novapass',
      :nova_user_password => 'novauserpass',
      :nova_api_db_password => 'novapassapi',
      :private_interface => 'enp0s1',
      :public_interface => 'enp0s2',
      :amqp_hosts => '127.0.0.1:5672',
    }
  end

  shared_examples_for 'nova controller configuration' do

    it 'contains openstack::nova::controller' do
      should contain_class('openstack::nova::controller')
    end

    it 'configures with the default params' do
    end


    it 'points to valid admin endpoint' do
      should contain_class('nova::api').with(
        :identity_uri => params[:keystone_identity_uri],
        :auth_uri => params[:keystone_auth_uri],
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
        :os_service_default => '<SERVICE DEFAULT>',
      }
    end

    it_configures 'nova controller configuration'
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
        :os_service_default => '<SERVICE DEFAULT>',
      }
    end

    it_configures 'nova controller configuration'
  end

end
