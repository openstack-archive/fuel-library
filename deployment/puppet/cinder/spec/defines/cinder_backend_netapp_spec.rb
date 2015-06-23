require 'spec_helper'

describe 'cinder::backend::netapp' do

  let(:title) {'netapp'}

  let :params do
    {
      :volume_backend_name          => 'netapp-cdot-nfs',
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
      is_expected.to contain_cinder_config('netapp/volume_driver').with_value(
        'cinder.volume.drivers.netapp.common.NetAppDriver')
      params_hash.each_pair do |config,value|
        is_expected.to contain_cinder_config("netapp/#{config}").with_value( value )
      end
    end

    it 'marks netapp_password as secret' do
      is_expected.to contain_cinder_config('netapp/netapp_password').with_secret( true )
    end

    it 'marks netapp_sa_password as secret' do
      is_expected.to contain_cinder_config('netapp/netapp_sa_password').with_secret( true )
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

  context 'with netapp_storage_family eseries' do
    before do
      params.merge!(:netapp_storage_family => 'eseries')
    end

    it 'sets use_multipath_for_image_xfer to true' do
      should contain_cinder_config('netapp/use_multipath_for_image_xfer').with({
        :value => 'true'
      })
    end
  end

  context 'with nfs_mount_options' do
    before do
      params.merge!(:nfs_mount_options => 'rw,proto=tcp,sec=sys')
    end

    it 'sets the nfs mount options' do
      should contain_cinder_config('netapp/nfs_mount_options').with({
        :value => 'rw,proto=tcp,sec=sys'
      })
    end
  end

  context 'netapp backend with additional configuration' do
    before do
      params.merge!({:extra_options => {'netapp/param1' => { 'value' => 'value1' }}})
    end

    it 'configure netapp backend with additional configuration' do
      should contain_cinder_config('netapp/param1').with({
        :value => 'value1'
      })
    end
  end

  context 'with NFS shares provided' do
    let (:req_params) { params.merge!({
        :nfs_shares => ['10.0.0.1:/test1', '10.0.0.2:/test2'],
        :nfs_shares_config => '/etc/cinder/shares.conf',
    }) }

    it 'writes NFS shares to file' do
      is_expected.to contain_file("#{req_params[:nfs_shares_config]}") \
        .with_content("10.0.0.1:/test1\n10.0.0.2:/test2")
    end
  end

  context 'with invalid NFS shares provided' do
    before do
      params.merge!({
        :nfs_shares => "not an array",
        :nfs_shares_config => '/etc/cinder/shares.conf',
      })
    end

    it_raises 'a Puppet::Error', /"not an array" is not an Array.  It looks to be a String/
  end

end
