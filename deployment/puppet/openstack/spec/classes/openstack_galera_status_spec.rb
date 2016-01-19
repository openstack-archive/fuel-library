require 'spec_helper'

describe 'openstack::galera::status' do

  shared_examples_for 'galera configuration' do

    context 'with mysql module with version < 2.2' do
      let :params do
        {
          :mysql_module => 2.1,
          :status_user     => 'user',
          :status_password => 'password',
        }
      end

      it 'should create grant with right privileges' do
        should contain_database_grant("user@%/*.*").with(
          :privileges => [ 'select_priv' ]
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
      }
    end

    it_configures 'galera configuration'
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

    it_configures 'galera configuration'
  end

end
