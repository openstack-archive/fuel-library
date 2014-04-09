require 'spec_helper'

describe 'cinder::volume::netapp' do

  let :params do
    {
      :netapp_login           => 'netapp',
      :netapp_password        => 'password',
      :netapp_server_hostname => '127.0.0.2',
    }
  end

  let :default_params do
    {
      :netapp_server_port           => '80',
      :netapp_size_multiplier       => '1.2',
      :netapp_storage_family        => 'ontap_cluster',
      :netapp_storage_protocol      => 'nfs',
      :netapp_transport_type        => 'http',
      :netapp_vfiler                => '',
      :netapp_volume_list           => '',
      :netapp_vserver               => '',
      :expiry_thres_minutes         => '720',
      :thres_avl_size_perc_start    => '20',
      :thres_avl_size_perc_stop     => '60',
      :nfs_shares_config            => '',
      :netapp_copyoffload_tool_path => '',
      :netapp_controller_ips        => '',
      :netapp_sa_password           => '',
      :netapp_storage_pools         => '',
      :netapp_webservice_path       => '/devmgr/v2',
    }
  end


  shared_examples_for 'netapp volume driver' do
    let :params_hash do
      default_params.merge(params)
    end

    it 'configures netapp volume driver' do
      should contain_cinder_config('DEFAULT/volume_driver').with_value(
        'cinder.volume.drivers.netapp.common.NetAppDriver')
      params_hash.each_pair do |config,value|
        should contain_cinder_config("DEFAULT/#{config}").with_value( value )
      end
    end

    it 'marks netapp_password as secret' do
      should contain_cinder_config('DEFAULT/netapp_password').with_secret( true )
    end
  end


  context 'with default parameters' do
    before do
      params = {}
    end

    it_configures 'netapp volume driver'
  end

  context 'with provided parameters' do
    it_configures 'netapp volume driver'
  end
end
