# author 'Aimon Bustardo <abustardo at morphlabs dot com>'
# license 'Apache License 2.0'
# description 'configures openstack cinder nexenta driver'
require 'spec_helper'

describe 'cinder::volume::nexenta' do

  let :params do
    { :nexenta_user     => 'nexenta',
      :nexenta_password => 'password',
      :nexenta_host     => '127.0.0.2',
    }
  end

  let :default_params do
    { :nexenta_volume              => 'cinder',
      :nexenta_target_prefix       => 'iqn:',
      :nexenta_target_group_prefix => 'cinder/',
      :nexenta_blocksize           => '8k',
      :nexenta_sparse              => true }
  end


  let :facts do
    { :osfamily => 'Debian' }
  end


  context 'with required params' do
    let :params_hash do
      default_params.merge(params)
    end

    it 'configures nexenta volume driver' do
      params_hash.each_pair do |config, value|
        is_expected.to contain_cinder_config("DEFAULT/#{config}").with_value(value)
      end
    end

    it 'marks nexenta_password as secret' do
      is_expected.to contain_cinder_config('DEFAULT/nexenta_password').with_secret( true )
    end

  end

  context 'nexenta volume drive with additional configuration' do
    before :each do
      params.merge!({:extra_options => {'nexenta_backend/param1' => {'value' => 'value1'}}})
    end

    it 'configure nexenta volume with additional configuration' do
      should contain_cinder__backend__nexenta('DEFAULT').with({
        :extra_options => {'nexenta_backend/param1' => {'value' => 'value1'}}
      })
    end

  end
end
