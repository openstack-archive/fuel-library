require 'spec_helper'

describe 'openstack::glance' do

  let :params do
    {
        :auth_uri => 'https://192.168.10.1:5000/',
        :identity_uri => 'https://192.168.10.1:35357/',
        :glance_user_password => "glance_password",
        :rabbit_password => "rabbit_password",
        :rabbit_hosts => "10.0.0.1, 10.0.0.2",
    }
  end

  shared_examples_for 'glance configuration' do

    it 'contains openstack::glance' do
      should contain_class('openstack::glance')
    end

    it 'configures with the default params' do
      should contain_class('glance::api').with(
        :database_connection => 'mysql://glance:glance@localhost/glance'
      )
    end

    context 'with keystone configured' do

      it 'contains keystone config for glance::api' do
        should contain_class('glance::api').with(
          :auth_uri     => params[:auth_uri],
          :identity_uri => params[:identity_uri],
        )
      end

      it 'contains keystone config for glance::registry' do
        should contain_class('glance::registry').with(
          :auth_uri     => params[:auth_uri],
          :identity_uri => params[:identity_uri],
        )
      end

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

    it_configures 'glance configuration'
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

    it_configures 'glance configuration'
  end

end
