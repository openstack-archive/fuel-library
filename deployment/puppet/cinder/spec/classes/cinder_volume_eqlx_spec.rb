require 'spec_helper'

describe 'cinder::volume::eqlx' do

  let :params do {
      :san_ip               => '192.168.100.10',
      :san_login            => 'grpadmin',
      :san_password         => '12345',
      :san_thin_provision   => true,
      :eqlx_group_name      => 'group-a',
      :eqlx_pool            => 'apool',
      :eqlx_use_chap        => true,
      :eqlx_chap_login      => 'chapadm',
      :eqlx_chap_password   => '56789',
      :eqlx_cli_timeout     => 31,
      :eqlx_cli_max_retries => 6,
  }
  end

  describe 'eqlx volume driver' do
    it 'configures eqlx volume driver' do
      should contain_cinder_config('DEFAULT/volume_driver').with_value('cinder.volume.drivers.eqlx.DellEQLSanISCSIDriver')
      should contain_cinder_config('DEFAULT/volume_backend_name').with_value('DEFAULT')

      params.each_pair do |config,value|
        should contain_cinder_config("DEFAULT/#{config}").with_value(value)
      end
    end

    it 'marks eqlx_chap_password as secret' do
      should contain_cinder_config('DEFAULT/eqlx_chap_password').with_secret( true )
    end

  end
end
