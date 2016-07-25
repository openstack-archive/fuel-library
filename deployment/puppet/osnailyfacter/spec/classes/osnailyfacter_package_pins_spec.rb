require 'spec_helper'

describe 'osnailyfacter::package_pins' do

  context 'on Ubuntu Trusty' do
    let :facts do
      {
        :osfamily               => 'Debian',
        :operatingsystem        => 'Ubuntu',
        :operatingsystemrelease => '14.04',
        :lsbdistid              => 'Ubuntu',
      }
    end

    context 'with default parameters' do
      it {
        should contain_class('osnailyfacter::package_pins')
        should_not contain_package('ubuntu-cloud-keyring')
      }
    end

    context 'with UCA and all pins' do
      let :params do
        {
          :repo_type    => 'uca',
          :pin_haproxy  => true,
          :pin_rabbitmq => true,
          :pin_ceph     => true,
        }
      end

      it 'should correctly configure pin versions' do
        should contain_class('osnailyfacter::package_pins')
        should contain_apt__pin('haproxy-mos').with(
          'packages' => 'haproxy',
          'version'  => '1.5.3-*',
          'priority' => '2000'
        )
        should contain_apt__pin('ceph-mos').with(
          'packages' => [ 'ceph', 'ceph-common', 'libradosstriper1',
                          'python-ceph', 'python-rbd', 'python-rados',
                          'python-cephfs', 'libcephfs1', 'librados2',
                          'librbd1', 'radosgw', 'rbd-fuse' ],
          'version'  => '0.94*',
          'priority' => '2000'
        )
        should contain_apt__pin('rabbitmq-server-mos').with(
          'packages' => 'rabbitmq-server',
          'version'  => '3.6*',
          'priority' => '2000'
        )
        should contain_apt__pin('openvswitch-mos').with(
          'packages' => 'openvswitch*',
          'version'  => '2.4.0*',
          'priority' => '2000'
        )
        should contain_package('ubuntu-cloud-keyring')
      end
    end
  end

  context 'on Ubuntu Xenial' do
    let :facts do
      {
        :osfamily               => 'Debian',
        :operatingsystem        => 'Ubuntu',
        :operatingsystemrelease => '16.04',
        :lsbdistid              => 'Ubuntu',
      }
    end

    context 'with default parameters' do
      it {
        should contain_class('osnailyfacter::package_pins')
        should_not contain_package('ubuntu-cloud-keyring')
      }
    end

    context 'with UCA and all pins' do
      let :params do
        {
          :repo_type    => 'uca',
          :pin_haproxy  => true,
          :pin_rabbitmq => true,
          :pin_ceph     => true,
        }
      end

      it 'should correctly configure pin versions' do
        should contain_class('osnailyfacter::package_pins')
        should contain_apt__pin('mos-python').with(
          'packages'   => 'python-*',
          'originator' => 'Mirantis',
          'priority'   => '499'
        )
        should contain_apt__pin('haproxy-mos').with(
          'packages' => 'haproxy',
          'version'  => '1.6.3-*',
          'priority' => '2000'
        )
        should_not contain_apt__pin('ceph-mos')
        should contain_apt__pin('rabbitmq-server-mos').with(
          'packages' => 'rabbitmq-server',
          'version'  => '3.6*',
          'priority' => '2000'
        )
        should_not contain_apt__pin('openvswitch-mos')
        should contain_package('ubuntu-cloud-keyring')
      end
    end
  end
end

