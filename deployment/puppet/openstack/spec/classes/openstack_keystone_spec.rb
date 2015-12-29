require 'spec_helper'

describe 'openstack::keystone' do

  let :params do
    {
      :admin_url => 'https://192.168.10.1:35357/',
      :internal_url => "http://10.0.0.1/5000/",
      :public_url => "http://10.0.0.1/5000/",
      :public_address => "10.0.0.1",
      :db_host => "10.0.0.1",
      :db_password => "dbpass",
      :admin_token => "$token",
    }
  end

  shared_examples_for 'keystone configuration' do

    it 'contains openstack::keystone' do
      should contain_class('openstack::keystone')
    end

    it 'configures with the default params' do
    end


    it 'points to valid admin endpoint' do
      should contain_class('keystone').with(
        :admin_endpoint => params[:admin_url],
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

    it_configures 'keystone configuration'
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

    it_configures 'keystone configuration'
  end

end
