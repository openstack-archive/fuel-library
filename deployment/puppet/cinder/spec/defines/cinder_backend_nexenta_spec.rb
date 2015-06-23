# author 'Aimon Bustardo <abustardo at morphlabs dot com>'
# license 'Apache License 2.0'
# description 'configures openstack cinder nexenta driver'
require 'spec_helper'

describe 'cinder::backend::nexenta' do
  let (:title) { 'nexenta' }

  let :params do
    { :nexenta_user     => 'nexenta',
      :nexenta_password => 'password',
      :nexenta_host     => '127.0.0.2' }
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
        is_expected.to contain_cinder_config("nexenta/#{config}").with_value(value)
      end
    end
  end

  context 'nexenta backend with additional configuration' do
    before do
      params.merge!({:extra_options => {'nexenta/param1' => { 'value' => 'value1' }}})
    end

    it 'configure nexenta backend with additional configuration' do
      should contain_cinder_config('nexenta/param1').with({
        :value => 'value1'
      })
    end
  end

end
