require 'spec_helper'
require 'shared-examples'
manifest = 'roles/cinder.pp'

# FIXME: neut_vlan.cinder-block-device.compute.yaml ubuntu
# HIERA: neut_vxlan_dvr.murano.sahara-cinder.yaml
# SKIP_HIERA: neut_vlan.cinder-block-device.compute

describe manifest do

  before(:each) do
    Noop.puppet_function_load :is_pkg_installed
    MockFunction.new(:is_pkg_installed) do |function|
      allow(function).to receive(:call).and_return false
    end
  end

  shared_examples 'catalog' do

  storage_hash = Noop.hiera_structure 'storage'
  ceilometer_hash = Noop.hiera_hash 'ceilometer', { 'enabled' => false }
  use_ceph = Noop.hiera 'use_ceph'
  volume_backend_name = storage_hash['volume_backend_names']
  kombu_compression = Noop.hiera 'kombu_compression', ''

  database_vip = Noop.hiera('database_vip')
  cinder_db_password = Noop.hiera_structure 'cinder/db_password', 'cinder'
  cinder_db_user = Noop.hiera_structure 'cinder/db_user', 'cinder'
  cinder_db_name = Noop.hiera_structure 'cinder/db_name', 'cinder'
  cinder = Noop.puppet_function 'roles_include', 'cinder'

  let(:manage_volumes) do
    if cinder and storage_hash['volumes_lvm']
      'iscsi'
    elsif storage_hash['volumes_ceph']
      'ceph'
    elsif storage_hash['volumes_block_device']
      'block'
    else
      false
    end
  end

  it 'should configure the database connection string' do
    if facts[:os_package_type] == 'debian'
      extra_params = '?charset=utf8&read_timeout=60'
    else
      extra_params = '?charset=utf8'
    end
    should contain_class('cinder').with(
      :database_connection => "mysql://#{cinder_db_user}:#{cinder_db_password}@#{database_vip}/#{cinder_db_name}#{extra_params}"
    )
  end

  if use_ceph and !(storage_hash['volumes_lvm']) and !(member($roles, 'cinder-vmware'))
      it { should contain_class('ceph') }
  end

  it { should contain_package('python-amqp') }

  if Noop.hiera_structure('use_ssl')
    glance_protocol = 'https'
    glance_internal_address = Noop.hiera_structure('use_ssl/glance_internal_hostname')
  else
    glance_protocol = 'http'
    glance_internal_address = Noop.hiera('management_vip')
  end
  glance_api_servers = "#{glance_protocol}://#{glance_internal_address}:9292"

  it 'should contain correct glance api servers addresses' do
    should contain_class('cinder::glance').with(
      'glance_api_servers' => glance_api_servers
    )
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

    it 'should contain proper config file for cinder' do
      should contain_cinder_config('BDD-backend/iscsi_helper').with(:value => 'tgtadm')
      should contain_cinder_config('BDD-backend/volume_driver').with(:value => 'cinder.volume.drivers.block_device.BlockDeviceDriver')
      should contain_cinder_config('BDD-backend/iscsi_ip_address').with(:value => iscsi_bind_host)
      should contain_cinder_config('BDD-backend/volume_group').with(:value => 'cinder')
      should contain_cinder_config('BDD-backend/volumes_dir').with(:value => '/var/lib/cinder/volumes')
      should contain_cinder_config('BDD-backend/available_devices').with(:value => disks_list)
    end
  end

  it 'ensures that cinder have proper volume_backend_name' do
    if cinder and storage_hash['volumes_lvm']
      should contain_cinder__backend__iscsi(volume_backend_name['volumes_lvm']).with(
        'volume_backend_name' => volume_backend_name['volumes_lvm']
      )
    elsif storage_hash['volumes_ceph']
      should contain_cinder__backend__rbd(volume_backend_name['volumes_ceph']).with(
       'volume_backend_name' => volume_backend_name['volumes_ceph']
      )
    elsif storage_hash['volumes_block_device']
      should contain_cinder__backend__bdd(volume_backend_name['volumes_block_device']).with(
       'volume_backend_name' => volume_backend_name['volumes_block_device']
      )
    else
      should_not contain_cinder_config('DEFAULT/volume_backend_name')
    end
  end

  let :ceilometer_hash do
    Noop.hiera_hash 'ceilometer', { 'enabled' => false }
  end

  if ceilometer_hash['enabled']
    it 'should contain notification_driver option' do
      should contain_cinder_config('DEFAULT/notification_driver').with(:value => ceilometer_hash['notification_driver'])
    end
  end

  it 'should check stuff that openstack cinder did' do
    is_expected.to contain_class('cinder')
    if manage_volumes
      is_expected.to contain_class('cinder::volume')
      is_expected.to contain_class('cinder::backends')
    else
      is_expected.to_not contain_class('cinder::volume')
      is_expected.to_not contain_class('cinder::backends')
    end
  end

  if ['gzip', 'bz2'].include?(kombu_compression)
    it 'should configure kombu compression' do
      should contain_cinder_config('oslo_messaging_rabbit/kombu_compression').with(:value => kombu_compression)
    end
  end

  end # end of shared_examples
  test_ubuntu_and_centos manifest
end

