require 'spec_helper'

describe 'nova::quota' do

  let :params do
    {}
  end

  let :default_params do
    { :quota_instances => 10,
      :quota_cores => 20,
      :quota_ram => 51200,
      :quota_floating_ips => 10,
      :quota_fixed_ips => -1,
      :quota_metadata_items => 128,
      :quota_injected_files => 5,
      :quota_injected_file_content_bytes => 10240,
      :quota_injected_file_path_length => 255,
      :quota_security_groups => 10,
      :quota_security_group_rules => 20,
      :quota_key_pairs => 100,
      :reservation_expire => 86400,
      :until_refresh => 0,
      :max_age => 0,
      :quota_driver => 'nova.quota.DbQuotaDriver' }
  end

  shared_examples_for 'nova quota' do
    let :params_hash do
      default_params.merge(params)
    end

    it 'configures quota in nova.conf' do
      params_hash.each_pair do |config,value|
        is_expected.to contain_nova_config("DEFAULT/#{config}").with_value( value )
      end
    end
  end

  context 'with default parameters' do
    it_configures 'nova quota'
  end

  context 'with provided parameters' do
    before do
      params.merge!({
        :quota_instances => 20,
        :quota_cores => 40,
        :quota_ram => 102400,
        :quota_floating_ips => 20,
        :quota_fixed_ips => 512,
        :quota_metadata_items => 256,
        :quota_injected_files => 10,
        :quota_injected_file_content_bytes => 20480,
        :quota_injected_file_path_length => 254,
        :quota_security_groups => 20,
        :quota_security_group_rules => 40,
        :quota_key_pairs => 200,
        :reservation_expire => 6400,
        :until_refresh => 30,
        :max_age => 60
      })
    end

    it_configures 'nova quota'
  end

  context 'with deprecated parameters' do
    let :params do {
        :quota_max_injected_files => 10,
        :quota_max_injected_file_content_bytes => 20480,
        :quota_injected_file_path_bytes => 254
      }
    end

    it {
      is_expected.to contain_nova_config('DEFAULT/quota_injected_files').with_value('10')
      is_expected.to contain_nova_config('DEFAULT/quota_injected_file_content_bytes').with_value('20480')
      is_expected.to contain_nova_config('DEFAULT/quota_injected_file_path_length').with_value('254')
    }
  end

  it { is_expected.to contain_nova_config('DEFAULT/quota_ram').with_value('51200') }

  describe 'when overriding params' do

    let :params do
      {:quota_ram => '1'}
    end

    it { is_expected.to contain_nova_config('DEFAULT/quota_ram').with_value('1') }

  end

end
