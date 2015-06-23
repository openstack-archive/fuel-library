require 'spec_helper'

describe 'cinder::setup_test_volume' do

  it { is_expected.to contain_package('lvm2').with(
        :ensure => 'present'
      ) }

  it { is_expected.to contain_file('/var/lib/cinder').with(
        :ensure => 'directory',
        :require => 'Package[cinder]'
      ) }

  it 'should contain volume creation execs' do
    is_expected.to contain_exec('create_/var/lib/cinder/cinder-volumes').with(
        :command => 'dd if=/dev/zero of="/var/lib/cinder/cinder-volumes" bs=1 count=0 seek=4G'
      )
    is_expected.to contain_exec('losetup /dev/loop2 /var/lib/cinder/cinder-volumes')
    is_expected.to contain_exec('pvcreate /dev/loop2')
    is_expected.to contain_exec('vgcreate cinder-volumes /dev/loop2')
  end
end
