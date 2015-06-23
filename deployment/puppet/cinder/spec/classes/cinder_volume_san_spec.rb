require 'spec_helper'

describe 'cinder::volume::san' do

  let :params do
    { :volume_driver   => 'cinder.volume.san.SolarisISCSIDriver',
      :san_ip          => '127.0.0.1',
      :san_login       => 'cluster_operator',
      :san_password    => '007',
      :san_clustername => 'storage_cluster',
    }
  end

  let :default_params do
    { :san_thin_provision => true,
      :san_login          => 'admin',
      :san_ssh_port       => 22,
      :san_is_local       => false,
      :ssh_conn_timeout   => 30,
      :ssh_min_pool_conn  => 1,
      :ssh_max_pool_conn  => 5 }
  end

  shared_examples_for 'a san volume driver' do
    let :params_hash do
      default_params.merge(params)
    end

    it 'configures cinder volume driver' do
      params_hash.each_pair do |config,value|
        is_expected.to contain_cinder_config("DEFAULT/#{config}").with_value( value )
      end
    end

    it 'marks san_password as secret' do
      is_expected.to contain_cinder_config('DEFAULT/san_password').with_secret( true )
    end

  end


  context 'with parameters' do
    it_configures 'a san volume driver'
  end

  context 'san volume driver with additional configuration' do
    before :each do
      params.merge!({:extra_options => { 'san_backend/param1' => {'value' => 'value1'}}})
    end

    it 'configure san volume with additional configuration' do
      should contain_cinder__backend__san('DEFAULT').with({
        :extra_options => {'san_backend/param1' => {'value' => 'value1'}}
      })
    end

  end
end
