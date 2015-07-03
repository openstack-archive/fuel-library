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
      is_expected.to contain_glance_api_config('glance_store/default_store').with_value('swift')
      is_expected.to contain_glance_api_config('glance_store/swift_store_key').with_value('key')
      is_expected.to contain_glance_api_config('glance_store/swift_store_user').with_value('user')
      is_expected.to contain_glance_api_config('glance_store/swift_store_auth_version').with_value('2')
      is_expected.to contain_glance_api_config('glance_store/swift_store_large_object_size').with_value('5120')
      is_expected.to contain_glance_api_config('glance_store/swift_store_auth_address').with_value('127.0.0.1:5000/v2.0/')
      is_expected.to contain_glance_api_config('glance_store/swift_store_container').with_value('glance')
      is_expected.to contain_glance_api_config('glance_store/swift_store_create_container_on_put').with_value(false)
      is_expected.to contain_glance_api_config('glance_store/swift_store_endpoint_type').with_value('internalURL')
    end

    it 'configures glance-cache.conf' do
      is_expected.to contain_glance_cache_config('glance_store/swift_store_key').with_value('key')
      is_expected.to contain_glance_cache_config('glance_store/swift_store_user').with_value('user')
      is_expected.to contain_glance_cache_config('glance_store/swift_store_auth_version').with_value('2')
      is_expected.to contain_glance_cache_config('glance_store/swift_store_large_object_size').with_value('5120')
      is_expected.to contain_glance_cache_config('glance_store/swift_store_auth_address').with_value('127.0.0.1:5000/v2.0/')
      is_expected.to contain_glance_cache_config('glance_store/swift_store_container').with_value('glance')
      is_expected.to contain_glance_cache_config('glance_store/swift_store_create_container_on_put').with_value(false)
    end
  end

  describe 'when overriding parameters' do
    let :params do
      {
        :swift_store_user                    => 'user',
        :swift_store_key                     => 'key',
        :swift_store_auth_version            => '1',
        :swift_store_large_object_size       => '100',
        :swift_store_auth_address            => '127.0.0.2:8080/v1.0/',
        :swift_store_container               => 'swift',
        :swift_store_create_container_on_put => true,
        :swift_store_endpoint_type           => 'publicURL'
      }
    end

    it 'configures glance-api.conf' do
      is_expected.to contain_glance_api_config('glance_store/swift_store_container').with_value('swift')
      is_expected.to contain_glance_api_config('glance_store/swift_store_create_container_on_put').with_value(true)
      is_expected.to contain_glance_api_config('glance_store/swift_store_auth_version').with_value('1')
      is_expected.to contain_glance_api_config('glance_store/swift_store_large_object_size').with_value('100')
      is_expected.to contain_glance_api_config('glance_store/swift_store_auth_address').with_value('127.0.0.2:8080/v1.0/')
      is_expected.to contain_glance_api_config('glance_store/swift_store_endpoint_type').with_value('publicURL')
    end

    it 'configures glance-cache.conf' do
      is_expected.to contain_glance_cache_config('glance_store/swift_store_container').with_value('swift')
      is_expected.to contain_glance_cache_config('glance_store/swift_store_create_container_on_put').with_value(true)
      is_expected.to contain_glance_cache_config('glance_store/swift_store_auth_version').with_value('1')
      is_expected.to contain_glance_cache_config('glance_store/swift_store_large_object_size').with_value('100')
      is_expected.to contain_glance_cache_config('glance_store/swift_store_auth_address').with_value('127.0.0.2:8080/v1.0/')
    end
  end
end
