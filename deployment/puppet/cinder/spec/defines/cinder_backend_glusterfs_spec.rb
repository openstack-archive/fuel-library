require 'spec_helper'

describe 'cinder::backend::glusterfs' do

  shared_examples_for 'glusterfs volume driver' do
    let(:title) {'mygluster'}

    let :params do
      {
        :glusterfs_shares           => ['10.10.10.10:/volumes', '10.10.10.11:/volumes'],
        :glusterfs_shares_config    => '/etc/cinder/other_shares.conf',
        :glusterfs_sparsed_volumes  => true,
        :glusterfs_mount_point_base => '/cinder_mount_point',
      }
    end

    it 'configures glusterfs volume driver' do
      should contain_cinder_config('mygluster/volume_driver').with_value(
        'cinder.volume.drivers.glusterfs.GlusterfsDriver')
      should contain_cinder_config('mygluster/glusterfs_shares_config').with_value(
        '/etc/cinder/other_shares.conf')
      should contain_cinder_config('mygluster/glusterfs_sparsed_volumes').with_value(
        true)
      should contain_cinder_config('mygluster/glusterfs_mount_point_base').with_value(
        '/cinder_mount_point')
      should contain_file('/etc/cinder/other_shares.conf').with(
        :content => "10.10.10.10:/volumes\n10.10.10.11:/volumes\n",
        :require => 'Package[cinder]',
        :notify  => 'Service[cinder-volume]'
      )
    end

    context "with an parameter which has been removed" do
      before do
        params.merge!({
          :glusterfs_disk_util => 'foo',
        })
      end
      it 'should fails' do
        expect { subject }.to raise_error(Puppet::Error, /glusterfs_disk_util is removed in Icehouse./)
      end
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_configures 'glusterfs volume driver'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_configures 'glusterfs volume driver'
  end

end
