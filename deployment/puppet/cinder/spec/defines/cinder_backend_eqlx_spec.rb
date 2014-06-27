require 'spec_helper'

describe 'cinder::backend::eqlx' do
  let (:config_group_name) { 'eqlx-1' }

  let (:title) { config_group_name }

  let :params do
    {
      :san_ip               => '192.168.100.10',
      :san_login            => 'grpadmin',
      :san_password         => '12345',
      :volume_backend_name  => 'Dell_EQLX',
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
    it 'configure eqlx volume driver' do
      should contain_cinder_config(
        "#{config_group_name}/volume_driver").with_value(
        'cinder.volume.drivers.eqlx.DellEQLSanISCSIDriver')
      params.each_pair do |config,value|
        should contain_cinder_config(
          "#{config_group_name}/#{config}").with_value(value)
      end
    end
  end
end
