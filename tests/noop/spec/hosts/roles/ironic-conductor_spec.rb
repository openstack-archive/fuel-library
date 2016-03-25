# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-controller.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-compute.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-cinder.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-mongo.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-controller.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-controller.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-compute.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-ceph-osd.yaml ubuntu
# RUN: neut_vlan.ironic.controller.yaml ubuntu
# RUN: neut_vlan.ironic.conductor.yaml ubuntu
# RUN: neut_vlan.compute.ssl.yaml ubuntu
# RUN: neut_vlan.compute.ssl.overridden.yaml ubuntu
# RUN: neut_vlan.compute.nossl.yaml ubuntu
# RUN: neut_vlan.cinder-block-device.compute.yaml ubuntu
# RUN: neut_vlan.ceph.controller-ephemeral-ceph.yaml ubuntu
# RUN: neut_vlan.ceph.compute-ephemeral-ceph.yaml ubuntu
# RUN: neut_vlan.ceph.ceil-primary-controller.overridden_ssl.yaml ubuntu
# RUN: neut_vlan.ceph.ceil-compute.overridden_ssl.yaml ubuntu
# RUN: neut_gre.generate_vms.yaml ubuntu
require 'spec_helper'
require 'shared-examples'
manifest = 'roles/ironic-conductor.pp'

describe manifest do
  shared_examples 'catalog' do
    rabbit_user = Noop.hiera_structure 'rabbit/user', 'nova'
    rabbit_password = Noop.hiera_structure 'rabbit/password'
    ironic_enabled = Noop.hiera_structure 'ironic/enabled'
    storage_config = Noop.hiera_structure 'storage'
    amqp_durable_queues = Noop.hiera_structure 'ironic/amqp_durable_queues', 'false'

    database_vip = Noop.hiera('database_vip')
    ironic_db_password = Noop.hiera_structure 'ironic/db_password', 'ironic'
    ironic_db_user = Noop.hiera_structure 'ironic/db_user', 'ironic'
    ironic_db_name = Noop.hiera_structure 'ironic/db_name', 'ironic'

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

      management_vip = Noop.hiera 'management_vip'
      service_endpoint = Noop.hiera 'service_endpoint', management_vip
      neutron_endpoint = Noop.hiera 'neutron_endpoint', service_endpoint
      neutron_url = "http://#{neutron_endpoint}:9696"
      ironic_user = Noop.hiera_structure 'ironic/user', 'ironic'
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
