require 'spec_helper'
require 'shared-examples'
manifest = 'roles/ironic-conductor.pp'

# HIERA: neut_vlan.ceph.controller-ephemeral-ceph neut_vlan.ceph.compute-ephemeral-ceph
# FACTS: ubuntu

describe manifest do
  shared_examples 'catalog' do
    rabbit_user = task.hiera_structure 'rabbit/user', 'nova'
    rabbit_password = task.hiera_structure 'rabbit/password'
    ironic_enabled = task.hiera_structure 'ironic/enabled'
    storage_config = task.hiera_structure 'storage'
    amqp_durable_queues = task.hiera_structure 'ironic/amqp_durable_queues', 'false'

    database_vip = task.hiera('database_vip')
    ironic_db_password = task.hiera_structure 'ironic/db_password', 'ironic'
    ironic_db_user = task.hiera_structure 'ironic/db_user', 'ironic'
    ironic_db_name = task.hiera_structure 'ironic/db_name', 'ironic'

    if ironic_enabled
      it 'should ensure that ironic-fa-deploy is installed' do
          should contain_package('ironic-fa-deploy').with('ensure' => 'present')
      end

      it 'should declare ironic class correctly' do
        should contain_class('ironic').with(
          'rabbit_userid'        => rabbit_user,
          'rabbit_password'      => rabbit_password,
          'enabled_drivers'      => ['fuel_ssh', 'fuel_ipmitool', 'fake', 'fuel_libvirt'],
          'control_exchange'     => 'ironic',
          'amqp_durable_queues'  => amqp_durable_queues,
          'database_max_retries' => '-1',
        )
      end

      it 'should configure the database connection string' do
        if facts[:os_package_type] == 'debian'
          extra_params = '?charset=utf8&read_timeout=60'
        else
          extra_params = '?charset=utf8'
        end
        should contain_class('ironic').with(
          :database_connection => "mysql://#{ironic_db_user}:#{ironic_db_password}@#{database_vip}/#{ironic_db_name}#{extra_params}"
        )
      end

      management_vip = task.hiera 'management_vip'
      service_endpoint = task.hiera 'service_endpoint', management_vip
      neutron_endpoint = task.hiera 'neutron_endpoint', service_endpoint
      neutron_url = "http://#{neutron_endpoint}:9696"
      ironic_user = task.hiera_structure 'ironic/user', 'ironic'
      temp_url_endpoint_type = (storage_config['images_ceph']) ? 'radosgw' : 'swift'
      it 'ironic config should have propper config options' do
        should contain_ironic_config('pxe/tftp_root').with('value' => '/var/lib/ironic/tftpboot')
        should contain_ironic_config('neutron/url').with('value' => neutron_url)
        should contain_ironic_config('keystone_authtoken/admin_user').with('value' => ironic_user)
        should contain_ironic_config('glance/temp_url_endpoint_type').with('value' => temp_url_endpoint_type)
      end

      tftp_root = '/var/lib/ironic/tftpboot'

      it "should create #{tftp_root}/pxelinux.0" do
        should contain_file("#{tftp_root}/pxelinux.0").with(
          'ensure' => 'present',
          'source' => '/usr/lib/syslinux/pxelinux.0'
        ).that_requires('Package[syslinux]')
      end

    end #end of ironic_enabled
  end #end of catalog

  test_ubuntu_and_centos manifest
end
