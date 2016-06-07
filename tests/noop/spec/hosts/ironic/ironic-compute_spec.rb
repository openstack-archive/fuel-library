# ROLE: primary-controller
# ROLE: controller
require 'spec_helper'
require 'shared-examples'
manifest = 'ironic/ironic-compute.pp'


describe manifest do

  before(:each) do
    Noop.puppet_function_load :is_pkg_installed
    MockFunction.new(:is_pkg_installed) do |function|
      allow(function).to receive(:call).and_return false
    end
  end

  shared_examples 'catalog' do

    nova_hash =  Noop.hiera_structure 'nova'

    ironic_user_password = Noop.hiera_structure 'ironic/user_password'
    ironic_enabled = Noop.hiera_structure 'ironic/enabled'

    network_metadata     = Noop.hiera 'network_metadata'
    memcache_roles       = Noop.hiera 'memcache_roles'
    memcache_addresses   = Noop.hiera 'memcached_addresses', false
    memcache_server_port = Noop.hiera 'memcache_server_port', '11211'

    database_vip = Noop.hiera('database_vip')
    nova_db_password = Noop.hiera_structure 'nova/db_password', 'nova'
    nova_db_user = Noop.hiera_structure 'nova/db_user', 'nova'
    nova_db_name = Noop.hiera_structure 'nova/db_name', 'nova'

    use_stderr = Noop.hiera 'use_stderr', false

    if nova_hash['notification_driver']
      nova_notification_driver = nova_hash['notification_driver']
    else
      nova_notification_driver = []
    end

    let(:memcache_nodes) do
      Noop.puppet_function 'get_nodes_hash_by_roles', network_metadata, memcache_roles
    end

    let(:memcache_address_map) do
      Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', memcache_nodes, 'mgmt/memcache'
    end

    let (:memcache_servers) do
      if not memcache_addresses
        memcache_address_map.values.map { |server| "#{server}:#{memcache_server_port}" }.join(",")
      else
        memcache_addresses.map { |server| "#{server}:#{memcache_server_port}" }.join(",")
      end
    end

    let(:ssl_hash) { Noop.hiera_hash 'use_ssl', {} }
    let(:admin_auth_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone', 'admin','protocol','http' }
    let(:admin_auth_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin', 'hostname', [Noop.hiera('service_endpoint', Noop.hiera('management_vip'))]}
    let(:admin_uri) { "#{admin_auth_protocol}://#{admin_auth_address}:35357" }

    let(:glance_endpoint_default) { Noop.hiera 'glance_endpoint', Noop.hiera('management_vip') }
    let(:glance_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'glance','internal','protocol','http' }
    let(:glance_endpoint) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'glance','internal','hostname', glance_endpoint_default}
    let(:glance_api_servers) { Noop.hiera 'glance_api_servers', "#{glance_protocol}://#{glance_endpoint}:9292" }

    if ironic_enabled
      it 'nova config should have correct ironic settings' do
        should contain_nova_config('ironic/admin_password').with(:value => ironic_user_password)
        should contain_nova_config('DEFAULT/compute_driver').with(:value => 'ironic.IronicDriver')
        should contain_nova_config('DEFAULT/compute_manager').with(:value => 'ironic.nova.compute.manager.ClusteredComputeManager')
        should contain_nova_config('ironic/admin_url').with(:value => "#{admin_uri}/v2.0")
        should contain_nova_config('neutron/auth_url').with(:value => "#{admin_uri}/v3")
        should contain_nova_config('DEFAULT/max_concurrent_builds').with(:value => '50')
      end

      it 'nova config should have proper queue settings' do
      end

      it 'nova config should have reserved_host_memory_mb set to 0' do
        should contain_nova_config('DEFAULT/reserved_host_memory_mb').with(:value => '0')
      end

      it 'nova config should contain right memcached servers list' do
        should contain_nova_config('keystone_authtoken/memcached_servers').with(
          'value' => memcache_servers,
        )
      end

      it 'nova-compute.conf should have host set to "ironic-compute"' do
        should contain_file('/etc/nova/nova-compute.conf').with('content'  => "[DEFAULT]\nhost=ironic-compute")
      end

      it 'nova-compute should manages by pacemaker, and should be disabled as system service' do
        expect(subject).to contain_pacemaker_resource('p_nova_compute_ironic').with(
                             :name               => "p_nova_compute_ironic",
                             :ensure             => "present",
                             :primitive_class    => "ocf",
                             :primitive_provider => "fuel",
                             :primitive_type     => "nova-compute",
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
                             :provider => "pacemaker_xml",
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
        facts[:processorcount] = 10
        max_overflow = Noop.hiera 'max_overflow', [facts[:processorcount] * 5 + 0, 60 + 0].min
        idle_timeout = Noop.hiera 'idle_timeout', '3600'
        max_retries = Noop.hiera 'max_retries', '-1'
        max_pool_size = Noop.hiera 'max_pool_size', [facts[:processorcount] * 5 + 0, 30 + 0].min

        should contain_class('nova').with(
          :database_connection    => "mysql://#{nova_db_user}:#{nova_db_password}@#{database_vip}/#{nova_db_name}#{extra_params}",
          :cinder_catalog_info    => Noop.puppet_function('pick', nova_hash['cinder_catalog_info'], 'volumev2:cinderv2:internalURL'),
          :use_stderr             => use_stderr,
          :notification_driver    => nova_notification_driver,
          :glance_api_servers     => glance_api_servers,
          :database_max_overflow  => max_overflow,
          :database_idle_timeout  => idle_timeout,
          :database_max_retries   => max_retries,
          :database_max_pool_size => max_pool_size,
        )
        should contain_class('nova::compute').with(
          :allow_resize_to_same_host => Noop.puppet_function('pick', nova_hash['allow_resize_to_same_host'], true)
        )
      end
    end
  end

  test_ubuntu_and_centos manifest
end
