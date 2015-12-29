require 'spec_helper'

describe 'openstack::controller' do

  let(:default_params) { {
    :public_address => nil,
    :public_interface => nil,
    :private_interface => nil,
    :debug => false,
  } }

  let(:params) { {} }

  shared_examples_for 'controller configuration' do
    let :p do
      default_params.merge(params)
    end


    context 'with a default config' do
      let :params do
        { :public_address => '10.0.0.1',
          :public_interface => 'eth0',
          :private_interface => 'eth1',
          :internal_address => '127.0.0.1',
          :admin_address => '127.0.0.1',
        }
      end

      it 'contains openstack::controller' do
        should contain_class('openstack::controller')
      end

      it 'configures with the default params' do
      end
    end

    context 'with keystone configured' do
      let :params do {
        :public_address => '10.0.0.1',
        :public_interface => 'eth0',
        :private_interface => 'eth1',
        :internal_address => '127.0.0.1',
        :admin_address => '127.0.0.1',
        :keystone_auth_uri => 'https://192.168.10.1:5000/',
        :keystone_identity_uri => 'https://192.168.10.1:35357/',
        :keystone_ec2_url => 'https://192.168.10.1:5000/v2.0/ec2tokens',
        }
      end

      it 'contains keystone config' do
        should contain_class('nova::api').with(
          :auth_uri     => params[:keystone_auth_uri],
          :identity_uri => params[:keystone_identity_uri],
          :keystone_ec2_url => params[:keystone_ec2_url],
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

    it_configures 'controller configuration'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
        :hostname => 'hostname.example.com',
        :physicalprocessorcount => 2,
        :memorysize_mb => 1024,
        :openstack_version => {'nova' => 'present' },
      }
    end

    it_configures 'controller configuration'
  end

end

