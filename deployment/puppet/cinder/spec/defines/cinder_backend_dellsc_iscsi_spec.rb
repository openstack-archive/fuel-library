require 'spec_helper'

describe 'cinder::backend::dellsc_iscsi' do

  let (:config_group_name) { 'dellsc_iscsi' }

  let (:title) { config_group_name }

  let :params do
    {
      :san_ip                => '172.23.8.101',
      :san_login             => 'Admin',
      :san_password          => '12345',
      :iscsi_ip_address      => '192.168.0.20',
      :dell_sc_ssn           => '64720',
    }
  end

  let :default_params do
    {
      :dell_sc_api_port      => 3033,
      :dell_sc_server_folder => 'srv',
      :dell_sc_volume_folder => 'vol',
      :iscsi_port            => 3260,
    }
  end

  shared_examples_for 'dellsc_iscsi volume driver' do
    let :params_hash do
      default_params.merge(params)
    end

    it 'configures cinder volume driver' do
      params_hash.each_pair do |config,value|
        is_expected.to contain_cinder_config("dellsc_iscsi/#{config}").with_value( value )
      end
    end
  end


  context 'with parameters' do
    it_configures 'dellsc_iscsi volume driver'
  end

  context 'dellsc_iscsi backend with additional configuration' do
    before do
      params.merge!({:extra_options => {'dellsc_iscsi/param1' => { 'value' => 'value1' }}})
    end

    it 'configure dellsc_iscsi backend with additional configuration' do
      should contain_cinder_config('dellsc_iscsi/param1').with({
        :value => 'value1'
      })
    end
  end

end
