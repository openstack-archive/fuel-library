require 'spec_helper'

describe 'cluster::galera_status' do

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
