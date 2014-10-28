require 'spec_helper'

describe 'glance::backend::file' do
  let :facts do
    { :osfamily => 'Debian' }
  end

  let :pre_condition do
    'class { "glance::api": keystone_password => "pass" }'
  end

  it 'configures glance-api.conf' do
    should contain_glance_api_config('glance_store/default_store').with_value('file')
    should contain_glance_api_config('glance_store/filesystem_store_datadir').with_value('/var/lib/glance/images/')
  end

  it 'configures glance-cache.conf' do
    should contain_glance_cache_config('glance_store/filesystem_store_datadir').with_value('/var/lib/glance/images/')
  end

  describe 'when overriding datadir' do
    let :params do
      {:filesystem_store_datadir => '/tmp/'}
    end

    it 'configures glance-api.conf' do
      should contain_glance_api_config('glance_store/filesystem_store_datadir').with_value('/tmp/')
    end

    it 'configures glance-cache.conf' do
      should contain_glance_cache_config('glance_store/filesystem_store_datadir').with_value('/tmp/')
    end
  end
end
