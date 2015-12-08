require 'spec_helper'

describe 'openstack::cinder' do

  let(:default_params) { {
    :sql_connection => 'mysql://user:pass@127.0.0.1/cinder',
    :cinder_user_password => 'secret',
    :glance_api_servers => 'http://127.0.0.1:9292',
  } }

  let(:params) { {} }

  shared_examples_for 'cinder configuration' do
    let :p do
      default_params.merge(params)
    end


    context 'with a default config' do
      let :params { {} }
      end

      it 'contains openstack::cinder' do
        should contain_class('openstack::cinder')
      end

      it 'contains cinder::glance' do
        should contain_class('cinder::glance')
      end

      it 'configures with the default params' do
      end
    end

    context 'with keystone config' do
      let :params { {
        :identity_uri => 'http://192.168.0.1:5000',
      } }
      end

      let :p do
        default_params.merge(params)
      end

      it 'contains ' do
        should contain_class('openstack::cinder')
      end

      it 'contains cinder::glance' do
        should contain_class('cinder::glance')
      end

      it 'configures with the default params' do
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

    it_configures 'cinder configuration'
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

    it_configures 'cinder configuration'
  end

end

