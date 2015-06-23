require 'spec_helper'

describe 'cinder::volume::netapp' do

  let :params do
    {
      :netapp_login                 => 'netapp',
      :netapp_password              => 'password',
      :netapp_server_hostname       => '127.0.0.2',
      :netapp_vfiler                => 'netapp_vfiler',
      :netapp_volume_list           => 'vol1,vol2',
      :netapp_vserver               => 'netapp_vserver',
      :netapp_partner_backend_name  => 'fc2',
      :netapp_copyoffload_tool_path => '/tmp/na_copyoffload_64',
      :netapp_controller_ips        => '10.0.0.2,10.0.0.3',
      :netapp_sa_password           => 'password',
      :netapp_storage_pools         => 'pool1,pool2',
    }
  end

  let :default_params do
    {
      :netapp_server_port           => '80',
      :netapp_size_multiplier       => '1.2',
      :netapp_storage_family        => 'ontap_cluster',
      :netapp_storage_protocol      => 'nfs',
      :netapp_transport_type        => 'http',
      :expiry_thres_minutes         => '720',
      :thres_avl_size_perc_start    => '20',
      :thres_avl_size_perc_stop     => '60',
      :nfs_shares_config            => '/etc/cinder/shares.conf',
      :netapp_eseries_host_type     => 'linux_dm_mp',
      :nfs_mount_options            => nil,
      :netapp_webservice_path       => '/devmgr/v2',
    }
  end


  shared_examples_for 'netapp volume driver' do
    let :params_hash do
      default_params.merge(params)
    end

    it 'configures netapp volume driver' do
      is_expected.to contain_cinder_config('DEFAULT/volume_driver').with_value(
        'cinder.volume.drivers.netapp.common.NetAppDriver')
      params_hash.each_pair do |config,value|
        is_expected.to contain_cinder_config("DEFAULT/#{config}").with_value( value )
      end
    end

    it 'marks netapp_password as secret' do
      is_expected.to contain_cinder_config('DEFAULT/netapp_password').with_secret( true )
    end

    it 'marks netapp_sa_password as secret' do
      is_expected.to contain_cinder_config('DEFAULT/netapp_sa_password').with_secret( true )
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

  context 'with NFS shares provided' do
    let (:req_params) { params.merge!({
        :nfs_shares => ['10.0.0.1:/test1', '10.0.0.2:/test2'],
        :nfs_shares_config => '/etc/cinder/shares.conf',
    }) }

    it 'writes NFS shares to file' do
      is_expected.to contain_file("#{req_params[:nfs_shares_config]}")
        .with_content("10.0.0.1:/test1\n10.0.0.2:/test2")
    end
  end

  context 'with netapp volume drivers additional configuration' do
    before do
      params.merge!({:extra_options => {'netapp_backend/param1' => { 'value' => 'value1' }}})
    end

    it 'configure netapp volume with additional configuration' do
      should contain_cinder__backend__netapp('DEFAULT').with({
        :extra_options => {'netapp_backend/param1' => {'value' => 'value1'}}
      })  
    end
  end

end
