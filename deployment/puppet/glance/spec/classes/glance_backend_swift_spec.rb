require 'spec_helper'

describe 'glance::backend::swift' do
  let :facts do
    {
      :osfamily => 'Debian'
    }
  end

  let :params do
    {
      :swift_store_user => 'user',
      :swift_store_key  => 'key',
    }
  end

  let :pre_condition do
    'class { "glance::api": keystone_password => "pass" }'
  end

  describe 'when default parameters' do

    it 'configures glance-api.conf' do
      should contain_glance_api_config('glance_store/default_store').with_value('swift')
      should contain_glance_api_config('glance_store/swift_store_large_object_size').with_value('5120')
      should contain_glance_api_config('glance_store/swift_store_container').with_value('glance')
      should contain_glance_api_config('glance_store/swift_store_create_container_on_put').with_value(false)
      should contain_glance_api_config('glance_store/swift_store_config_file').with_value('/etc/glance/glance-swift.conf')
      should contain_glance_api_config('glance_store/default_swift_reference').with_value('ref1')
      should contain_glance_swift_config('ref1/key').with_value('key')
      should contain_glance_swift_config('ref1/user').with_value('user')
      should contain_glance_swift_config('ref1/auth_version').with_value('2')
      should contain_glance_swift_config('ref1/auth_address').with_value('127.0.0.1:5000/v2.0/')
    end

  end

  describe 'when overriding parameters' do
    let :params do
      {
        :swift_store_user                    => 'user2',
        :swift_store_key                     => 'key2',
        :swift_store_auth_version            => '1',
        :swift_store_large_object_size       => '100',
        :swift_store_auth_address            => '127.0.0.2:8080/v1.0/',
        :swift_store_container               => 'swift',
        :swift_store_create_container_on_put => true,
        :default_swift_reference             => 'swift_creds',
      }
    end

    it 'configures glance-api.conf' do
      should contain_glance_api_config('glance_store/swift_store_container').with_value('swift')
      should contain_glance_api_config('glance_store/swift_store_create_container_on_put').with_value(true)
      should contain_glance_api_config('glance_store/swift_store_large_object_size').with_value('100')
      should contain_glance_api_config('glance_store/default_swift_reference').with_value('swift_creds')
      should contain_glance_swift_config('swift_creds/key').with_value('key2')
      should contain_glance_swift_config('swift_creds/user').with_value('user2')
      should contain_glance_swift_config('swift_creds/auth_version').with_value('1')
      should contain_glance_swift_config('swift_creds/auth_address').with_value('127.0.0.2:8080/v1.0/')
    end

  end
end
