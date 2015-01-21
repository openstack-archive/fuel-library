require 'spec_helper'

describe 'cinder::setup_test_volume' do

  it { should contain_package('lvm2').with(
        :ensure => 'present'
      ) }

  it { should contain_file('/var/lib/cinder').with(
        :ensure => 'directory',
        :require => 'Package[cinder]'
      ) }

  it 'should contain volume creation execs' do
    should contain_exec('create_/var/lib/cinder/cinder-volumes').with(
        :command => 'dd if=/dev/zero of="/var/lib/cinder/cinder-volumes" bs=1 count=0 seek=4G'
      )
    should contain_exec('losetup /dev/loop2 /var/lib/cinder/cinder-volumes')
    should contain_exec('pvcreate /dev/loop2')
    should contain_exec('vgcreate cinder-volumes /dev/loop2')
  end
end
