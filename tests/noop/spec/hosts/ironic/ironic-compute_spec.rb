require 'spec_helper'
require 'shared-examples'
manifest = 'roles/ironic-compute.pp'

# SKIP_HIERA: neut_vlan.ironic.controller

describe manifest do

  before(:each) do
    Noop.puppet_function_load :is_pkg_installed
    MockFunction.new(:is_pkg_installed) do |function|
      allow(function).to receive(:call).and_return false
    end
  end

  shared_examples 'catalog' do
    ironic_user_password = Noop.hiera_structure 'ironic/user_password'
    ironic_enabled = Noop.hiera_structure 'ironic/enabled'

    network_metadata     = Noop.hiera 'network_metadata'
    memcache_server_port = Noop.hiera 'memcache_server_port', '22122'

    database_vip = Noop.hiera('database_vip')
    nova_db_password = Noop.hiera_structure 'nova/db_password', 'nova'
    nova_db_user = Noop.hiera_structure 'nova/db_user', 'nova'
    nova_db_name = Noop.hiera_structure 'nova/db_name', 'nova'

    let (:memcache_servers) do
      "127.0.0.1:#{memcache_server_port}"
    end

    public_ssl_hash = Noop.hiera('public_ssl')
    let(:ssl_hash) { Noop.hiera_hash 'use_ssl', {} }
    let(:admin_auth_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone', 'admin','protocol','http' }
    let(:admin_auth_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin', 'hostname', [Noop.hiera('service_endpoint', Noop.hiera('management_vip'))]}
    let(:admin_uri) { "#{admin_auth_protocol}://#{admin_auth_address}:35357" }

    if ironic_enabled
      it 'nova config should have correct ironic settings' do
        should contain_nova_config('ironic/admin_password').with(:value => ironic_user_password)
        should contain_nova_config('DEFAULT/compute_driver').with(:value => 'ironic.IronicDriver')
        should contain_nova_config('DEFAULT/compute_manager').with(:value => 'ironic.nova.compute.manager.ClusteredComputeManager')
        should contain_nova_config('ironic/admin_url').with(:value => "#{admin_uri}/v2.0")
        should contain_nova_config('neutron/admin_auth_url').with(:value => "#{admin_uri}/v2.0")
      end

      it 'nova config should have reserved_host_memory_mb set to 0' do
        should contain_nova_config('DEFAULT/reserved_host_memory_mb').with(:value => '0')
      end

      it 'nova config should contain right memcached servers list' do
        should contain_nova_config('DEFAULT/memcached_servers').with(
          'value' => memcache_servers,
        )
      end

      it 'nova-compute.conf should have host set to "ironic-compute"' do
        should contain_file('/etc/nova/nova-compute.conf').with('content'  => "[DEFAULT]\nhost=ironic-compute")
      end

      it 'nova-compute should manages by pacemaker, and should be disabled as system service' do
        expect(subject).to contain_cs_resource('p_nova_compute_ironic').with(
                             :name            => "p_nova_compute_ironic",
                             :ensure          => "present",
                             :primitive_class => "ocf",
                             :provided_by     => "pacemaker",
                             :primitive_type  => "nova-compute",
                             :metadata        => {"resource-stickiness" => "1"},
                             :parameters      => {"config"                => "/etc/nova/nova.conf",
                                                  "pid"                   => "/var/run/nova/nova-compute-ironic.pid",
                                                  "additional_parameters" => "--config-file=/etc/nova/nova-compute.conf"
                                                 },
                             )
        expect(subject).to contain_service('p_nova_compute_ironic').with(
                             :name     => "p_nova_compute_ironic",
                             :ensure   => "running",
                             :enable   => true,
                             :provider => "pacemaker",
                             )
        expect(subject).to contain_service('nova-compute').with(
                             :name     => "nova-compute",
                             :ensure   => "stopped",
                             :enable   => false,
                             )
      end

      it 'should configure the database connection string' do
        if facts[:os_package_type] == 'debian'
          extra_params = '?charset=utf8&read_timeout=60'
        else
          extra_params = '?charset=utf8'
        end
        should contain_class('nova').with(
          :database_connection => "mysql://#{nova_db_user}:#{nova_db_password}@#{database_vip}/#{nova_db_name}#{extra_params}"
        )
      end
    end
  end

  test_ubuntu_and_centos manifest
end
