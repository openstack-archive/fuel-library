require 'spec_helper'

describe 'cinder::backend::nfs' do

  let(:title) {'hippo'}

  let :params do
    {
      :nfs_servers          => ['10.10.10.10:/shares', '10.10.10.10:/shares2'],
      :nfs_mount_options    => 'vers=3',
      :nfs_shares_config    => '/etc/cinder/other_shares.conf',
      :nfs_disk_util        => 'du',
      :nfs_sparsed_volumes  => true,
      :nfs_mount_point_base => '/cinder_mount_point',
      :nfs_used_ratio       => '0.7',
      :nfs_oversub_ratio    => '0.9'
    }
  end

  describe 'nfs volume driver' do

    it 'configures nfs volume driver' do
      should contain_cinder_config('hippo/volume_backend_name').with(
        :value => 'hippo')
      should contain_cinder_config('hippo/volume_driver').with_value(
        'cinder.volume.drivers.nfs.NfsDriver')
      should contain_cinder_config('hippo/nfs_shares_config').with_value(
        '/etc/cinder/other_shares.conf')
      should contain_cinder_config('hippo/nfs_mount_options').with_value(
        'vers=3')
      should contain_cinder_config('hippo/nfs_sparsed_volumes').with_value(
        true)
      should contain_cinder_config('hippo/nfs_mount_point_base').with_value(
        '/cinder_mount_point')
      should contain_cinder_config('hippo/nfs_disk_util').with_value(
        'du')
      should contain_cinder_config('hippo/nfs_used_ratio').with_value(
        '0.7')
      should contain_cinder_config('hippo/nfs_oversub_ratio').with_value(
        '0.9')
      should contain_file('/etc/cinder/other_shares.conf').with(
        :content => "10.10.10.10:/shares\n10.10.10.10:/shares2",
        :require => 'Package[cinder]',
        :notify  => 'Service[cinder-volume]'
      )
    end
  end
end
