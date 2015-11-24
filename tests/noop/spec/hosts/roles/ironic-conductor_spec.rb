require 'spec_helper'
require 'shared-examples'
manifest = 'roles/ironic-conductor.pp'

describe manifest do
  shared_examples 'catalog' do
    rabbit_user = Noop.hiera_structure 'rabbit/user', 'nova'
    rabbit_password = Noop.hiera_structure 'rabbit/password'
    ironic_enabled = Noop.hiera_structure 'ironic/enabled'
    storage_config = Noop.hiera_structure 'storage'

    if ironic_enabled
      it 'should ensure that ironic-fa-deploy is installed' do
          should contain_package('ironic-fa-deploy').with('ensure' => 'present')
      end

      it 'should declare ironic class correctly' do
        should contain_class('ironic').with(
          'rabbit_userid'   => rabbit_user,
          'rabbit_password' => rabbit_password,
          'enabled_drivers' => ['fuel_ssh', 'fuel_ipmitool', 'fake'],
        )
      end

      management_vip = Noop.hiera 'management_vip'
      service_endpoint = Noop.hiera 'service_endpoint', management_vip
      neutron_endpoint = Noop.hiera 'neutron_endpoint', service_endpoint
      neutron_url = "http://#{neutron_endpoint}:9696"
      ironic_user = Noop.hiera_structure 'ironic/user', 'ironic'
      if storage_config && storage_config.has_key?('images_ceph') && storage_config['images_ceph']
        temp_url_endpoint_type = 'radosgw'
      else
        temp_url_endpoint_type = 'swift'
      end
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
