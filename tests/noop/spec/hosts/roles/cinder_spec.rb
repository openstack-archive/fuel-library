require 'spec_helper'
require 'shared-examples'
manifest = 'roles/cinder.pp'

describe manifest do
  shared_examples 'catalog' do

  storage_hash = Noop.hiera 'storage_hash'

  if Noop.hiera 'use_ceph' and !(storage_hash['volumes_lvm'])
      it { should contain_class('ceph') }
  end

  it { should contain_package('python-amqp') }

  if Noop.hiera_structure('use_ssl')
    internal_auth_protocol = 'https'
    internal_auth_address  = Noop.hiera_structure('use_ssl/keystone_internal_hostname')
    glance_protocol = 'https'
    glance_internal_address = Noop.hiera_structure('use_ssl/glance_internal_hostname')
  else
    internal_auth_protocol = 'http'
    internal_auth_address  = Noop.hiera 'service_endpoint'
    glance_protocol = 'http'
    glance_internal_address = Noop.hiera('management_vip')
  end
  auth_uri           = "#{internal_auth_protocol}://#{internal_auth_address}:5000/"
  glance_api_servers = "#{glance_protocol}://#{glance_internal_address}:9292"

  it 'should contain correct glance api servers addresses' do
    should contain_class('openstack::cinder').with(
      'glance_api_servers' => glance_api_servers
    )
  end

  it 'ensures cinder_config contains auth_uri and identity_uri ' do
    should contain_cinder_config('keystone_authtoken/auth_uri').with(:value  => auth_uri)
    should contain_cinder_config('keystone_authtoken/identity_uri').with(:value  => auth_uri)
    should contain_cinder_config('DEFAULT/auth_strategy').with(:value  => 'keystone')
  end

  it 'should disable use_stderr option' do
    should contain_cinder_config('DEFAULT/use_stderr').with(:value => 'false')
  end

  if storage_hash['volumes_block_device']
    disks_metadata = Noop.hiera('node_volumes')

    let (:disks_list) do
      disks_list = Noop.puppet_function('get_disks_list_by_role', disks_metadata, 'cinder-block-device')
    end

    let (:iscsi_bind_host) do
      iscsi_bind_host = Noop.puppet_function('get_network_role_property', 'cinder/iscsi', 'ipaddr')
    end

    it 'should contain disks list for cinder block device role' do
      should contain_class('openstack::cinder').with(
        :physical_volume => disks_list,
        :manage_volumes  => 'fake',
      )
    end

    it 'should contain proper config file for cinder' do
      should contain_cinder_config('DEFAULT/iscsi_helper').with(:value => 'fake')
      should contain_cinder_config('DEFAULT/iscsi_protocol').with(:value => 'iscsi')
      should contain_cinder_config('DEFAULT/volume_backend_name').with(:value => 'DEFAULT')
      should contain_cinder_config('DEFAULT/volume_driver').with(:value => 'cinder.volume.drivers.block_device.BlockDeviceDriver')
      should contain_cinder_config('DEFAULT/iscsi_ip_address').with(:value => iscsi_bind_host)
      should contain_cinder_config('DEFAULT/volume_group').with(:value => 'cinder')
      should contain_cinder_config('DEFAULT/volume_dir').with(:value => '/var/lib/cinder/volumes')
      should contain_cinder_config('DEFAULT/volume_clear').with(:value => 'zero')
      should contain_cinder_config('DEFAULT/available_devices').with(:value => disks_list)
    end
  end

  end
  test_ubuntu_and_centos manifest
end

