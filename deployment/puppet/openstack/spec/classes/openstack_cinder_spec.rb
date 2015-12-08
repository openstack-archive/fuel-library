require 'spec_helper'

describe 'openstack::cinder' do

  let(:default_params) do {
    :sql_connection => 'mysql://user:pass@127.0.0.1/cinder',
    :cinder_user_password => 'secret',
    :glance_api_servers => 'http://127.0.0.1:9292',
    }
  end

  let(:params) do
    default_params.merge(params)
  end


  shared_examples_for 'cinder configuration' do
    let :p do
      default_params.merge(params)
    end


    context 'with a default config' do
      #let :params do {} end

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
      let :params do {
        :identity_uri => 'http://192.168.0.1:5000',
        }
      end

      let :p do
        default_params.merge(params)
      end

      it 'contains keymgr keystone config' do
        should contain_class('cinder::api').with(
          :identity_uri => 'http://192.168.1.:5000',
          :keymgr_encryption_auth_url => 'http://192.168.0.1:5000/v3',
        )
      end

      it 'contains cinder::glance' do
        should contain_class('cinder::glance')
      end

      it 'configures with the default params' do
      end
    end
  end
end
