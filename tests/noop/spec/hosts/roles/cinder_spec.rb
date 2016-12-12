require 'spec_helper'
require 'shared-examples'
manifest = 'roles/cinder.pp'

describe manifest do
  shared_examples 'catalog' do

  storage_hash = Noop.hiera 'storage'
  volume_group = Noop.hiera('cinder_volume_group', 'cinder')
  cinder = Noop.puppet_function 'roles_include', 'cinder'

  if cinder and storage_hash['volumes_lvm']
    it 'sets up filtering for LVM Cinder volumes' do

      cinder_lvm_filter = "\"r|^/dev/#{volume_group}/.*|\""

      should contain_file_line('lvm-conf-set-cinder-filter').with(
        'ensure' => 'present',
        'path'   => '/etc/lvm/lvm.conf',
        'line'   => "global_filter = #{cinder_lvm_filter}",
        'match'  => 'global_filter\ \=\ ',
        'tag'    => 'lvm-conf-file-line'
      ).that_notifies('Exec[Update initramfs]')

      should contain_exec('Update initramfs').with(
        'command'     => 'update-initramfs -u -k all',
        'path'        => '/usr/bin:/bin:/usr/sbin:/sbin',
        'refreshonly' => 'true')
    end
  end

  if Noop.hiera 'use_ceph' and !(storage_hash['volumes_lvm'])
      it { should contain_class('ceph') }
  end

  it { should contain_package('python-amqp') }

  keystone_auth_host = Noop.hiera 'service_endpoint'
  auth_uri           = "http://#{keystone_auth_host}:5000/"

  it 'ensures cinder_config contains auth_uri and identity_uri ' do
    should contain_cinder_config('keystone_authtoken/auth_uri').with(:value  => auth_uri)
    should contain_cinder_config('keystone_authtoken/identity_uri').with(:value  => auth_uri)
    should contain_cinder_config('DEFAULT/auth_strategy').with(:value  => 'keystone')
  end

  it 'should disable use_stderr option' do
    should contain_cinder_config('DEFAULT/use_stderr').with(:value => 'false')
  end

  end
  test_ubuntu_and_centos manifest
end

