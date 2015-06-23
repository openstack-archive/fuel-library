require 'spec_helper'

describe 'cinder::volume::emc_vnx' do
  let :req_params do
    {
      :san_ip                => '127.0.0.2',
      :san_login             => 'emc',
      :san_password          => 'password',
      :iscsi_ip_address      => '127.0.0.3',
      :storage_vnx_pool_name => 'emc-storage-pool'
    }
  end

  let :facts do
    {:osfamily => 'Redhat' }
  end

  let :params do
    req_params
  end

  describe 'emc vnx volume driver' do
    it 'configure emc vnx volume driver' do
      is_expected.to contain_cinder_config('DEFAULT/volume_driver').with_value('cinder.volume.drivers.emc.emc_cli_iscsi.EMCCLIISCSIDriver')
      is_expected.to contain_cinder_config('DEFAULT/san_ip').with_value('127.0.0.2')
      is_expected.to contain_cinder_config('DEFAULT/san_login').with_value('emc')
      is_expected.to contain_cinder_config('DEFAULT/san_password').with_value('password')
      is_expected.to contain_cinder_config('DEFAULT/iscsi_ip_address').with_value('127.0.0.3')
      is_expected.to contain_cinder_config('DEFAULT/storage_vnx_pool_name').with_value('emc-storage-pool')
    end
  end

  describe 'emc vnx volume driver with additional configuration' do
    before :each do
      params.merge!({:extra_options => {'emc_vnx_backend/param1' => {'value' => 'value1'}}})
    end

    it 'configure emc vnx volume with additional configuration' do
      should contain_cinder__backend__emc_vnx('DEFAULT').with({
        :extra_options => {'emc_vnx_backend/param1' => {'value' => 'value1'}}
      })
    end
  end


end
