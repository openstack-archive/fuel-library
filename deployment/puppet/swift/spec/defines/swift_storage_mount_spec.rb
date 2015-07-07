require 'spec_helper'
describe 'swift::storage::mount' do
  # TODO add unit tests

  let :title do
    'dans_mount_point'
  end

  describe 'with defaults params' do
    let :params do
      {
        :device => '/dev/sda'
      }
    end

    it { is_expected.to contain_mount('/srv/node/dans_mount_point').with(
      :ensure  => 'present',
      :device  => '/dev/sda',
      :fstype  => 'xfs',
      :options => 'noatime,nodiratime,nobarrier,logbufs=8',
      :require => 'File[/srv/node/dans_mount_point]'
    )}

  end

  describe 'when mounting a loopback device' do

    let :params do
      {
        :device   => '/dev/sda',
        :loopback => true
      }
    end

    it { is_expected.to contain_mount('/srv/node/dans_mount_point').with(
      :device  => '/dev/sda',
      :options => 'noatime,nodiratime,nobarrier,loop,logbufs=8'
    )}

  end

  describe 'when mounting a loopback device on selinux system' do
    let :params do
      {
        :device => '/dev/sda'
      }
    end

    let :facts do
      {
        :selinux => 'true',
      }
    end

    it { is_expected.to contain_exec("restorecon_mount_dans_mount_point").with(
      {:command     => "restorecon /srv/node/dans_mount_point",
       :path        => ['/usr/sbin', '/sbin'],
       :refreshonly => true}
    )}

  end
end
