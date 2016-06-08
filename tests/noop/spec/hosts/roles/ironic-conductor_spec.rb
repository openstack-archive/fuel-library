# ROLE: ironic

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
          :database_connection => "mysql+pymysql://#{ironic_db_user}:#{ironic_db_password}@#{database_vip}/#{ironic_db_name}#{extra_params}"
        )
      end

      management_vip = Noop.hiera 'management_vip'
      service_endpoint = Noop.hiera 'service_endpoint', management_vip
      neutron_endpoint = Noop.hiera 'neutron_endpoint', service_endpoint
      ironic_user = Noop.hiera_structure 'ironic/user', 'ironic'
      temp_url_endpoint_type = (storage_config['images_ceph']) ? 'radosgw' : 'swift'

      let(:public_ssl_hash) { Noop.hiera_hash('public_ssl') }
      let(:ssl_hash) { Noop.hiera_hash 'use_ssl', {} }
      let(:service_endpoint) { Noop.hiera 'service_endpoint' }
      let(:neutron_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'neutron','internal','protocol','http' }
      let(:neutron_endpoint) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'neutron','internal','hostname', management_vip }
      let(:neutron_url) { "#{neutron_protocol}://#{neutron_endpoint}:9696" }
      let(:internal_auth_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','protocol','http' }
      let(:internal_auth_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','hostname', [ service_endpoint, management_vip ] }
      let(:internal_auth_uri) { "#{internal_auth_protocol}://#{internal_auth_address}:5000" }
      let(:admin_identity_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','protocol','http' }
      let(:admin_identity_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','hostname', [ service_endpoint, management_vip ] }
      let(:admin_identity_uri) { "#{internal_auth_protocol}://#{internal_auth_address}:35357" }


      it 'ironic config should have propper config options' do
        should contain_ironic_config('pxe/tftp_root').with('value' => '/var/lib/ironic/tftpboot')
        should contain_ironic_config('neutron/url').with('value' => neutron_url)
        should contain_ironic_config('keystone_authtoken/auth_uri').with('value' => internal_auth_uri)
        should contain_ironic_config('keystone_authtoken/identity_uri').with('value' => admin_identity_uri)
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
