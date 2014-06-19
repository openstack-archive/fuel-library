require 'spec_helper'

describe 'cinder::setup_test_volume' do

  it { should contain_package('lvm2').with(
        :ensure => 'present'
      ) }

  it 'should contain volume creation execs' do
    should contain_exec('/bin/dd if=/dev/zero of=cinder-volumes bs=1 count=0 seek=4G')
    should contain_exec('/sbin/losetup /dev/loop2 cinder-volumes')
    should contain_exec('/sbin/pvcreate /dev/loop2')
    should contain_exec('/sbin/vgcreate cinder-volumes /dev/loop2')
  end
end
