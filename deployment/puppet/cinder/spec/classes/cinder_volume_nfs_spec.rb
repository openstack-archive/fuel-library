require 'spec_helper'

describe 'cinder::volume::nfs' do

  let :params do
    {
      :nfs_servers          => ['10.10.10.10:/shares', '10.10.10.10:/shares2'],
      :nfs_mount_options    => 'vers=3',
      :nfs_shares_config    => '/etc/cinder/other_shares.conf',
      :nfs_disk_util        => 'du',
      :nfs_sparsed_volumes  => true,
      :nfs_mount_point_base => '/cinder_mount_point',
      :nfs_used_ratio       => '0.95',
      :nfs_oversub_ratio    => '1.0',
    }
  end

  describe 'nfs volume driver' do
    it 'configures nfs volume driver' do
      should contain_cinder_config('DEFAULT/volume_driver').with_value(
        'cinder.volume.drivers.nfs.NfsDriver')
      should contain_cinder_config('DEFAULT/nfs_shares_config').with_value(
        '/etc/cinder/other_shares.conf')
      should contain_cinder_config('DEFAULT/nfs_mount_options').with_value(
        'vers=3')
      should contain_cinder_config('DEFAULT/nfs_sparsed_volumes').with_value(
        true)
      should contain_cinder_config('DEFAULT/nfs_mount_point_base').with_value(
        '/cinder_mount_point')
      should contain_cinder_config('DEFAULT/nfs_disk_util').with_value(
        'du')
      should contain_cinder_config('DEFAULT/nfs_used_ratio').with_value(
        '0.95')
      should contain_cinder_config('DEFAULT/nfs_oversub_ratio').with_value(
        '1.0')
      should contain_file('/etc/cinder/other_shares.conf').with(
        :content => "10.10.10.10:/shares\n10.10.10.10:/shares2",
        :require => 'Package[cinder]',
        :notify  => 'Service[cinder-volume]'
      )
    end
  end
end
