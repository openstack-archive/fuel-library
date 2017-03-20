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

    ironic_enabled = Noop.hiera_structure 'ironic/enabled'

    database_vip = Noop.hiera('database_vip')
    nova_db_type = Noop.hiera_structure 'nova/db_type', 'mysql+pymysql'
    nova_db_password = Noop.hiera_structure 'nova/db_password', 'nova'
    nova_db_user = Noop.hiera_structure 'nova/db_user', 'nova'
    nova_db_name = Noop.hiera_structure 'nova/db_name', 'nova'

    use_stderr = Noop.hiera 'use_stderr', false

    management_vip = Noop.hiera('management_vip')

    if nova_hash['notification_driver']
      nova_notification_driver = nova_hash['notification_driver']
    else
      nova_notification_driver = []
    end

    let(:ssl_hash) { Noop.hiera_hash 'use_ssl', {} }
    let(:admin_auth_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone', 'admin','protocol','http' }
    let(:admin_auth_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin', 'hostname', [Noop.hiera('service_endpoint', management_vip)]}
    let(:admin_uri) { "#{admin_auth_protocol}://#{admin_auth_address}:35357" }

    let(:ironic_tenant) { Noop.hiera_structure 'ironic/tenant', 'services' }
    let(:ironic_username) { Noop.hiera_structure 'ironic/auth_name', 'ironic' }
    let(:ironic_user_password) { Noop.hiera_structure 'ironic/user_password', 'ironic' }

    let(:ironic_endpoint_default) { Noop.hiera_hash 'ironic_endpoint', management_vip }
    let(:ironic_protocol) { Noop.puppet_function 'get_ssl_property', ssl_hash,{},'ironic','internal','protocol','http' }
    let(:ironic_endpoint) { Noop.puppet_function 'get_ssl_property', ssl_hash,{},'ironic','internal','hostname', ironic_endpoint_default}

    let(:glance_endpoint_default) { Noop.hiera 'glance_endpoint', management_vip }
    let(:glance_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'glance','internal','protocol','http' }
    let(:glance_endpoint) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'glance','internal','hostname', glance_endpoint_default }
    let(:glance_api_servers) { Noop.hiera 'glance_api_servers', "#{glance_protocol}://#{glance_endpoint}:9292" }
    let(:region_name) { Noop.hiera 'region', 'RegionOne' }
    let(:transport_url) { Noop.hiera 'transport_url', 'rabbit://guest:password@127.0.0.1:5672/' }

    if ironic_enabled

      it 'nova config should have correct ironic settings' do
        should contain_nova_config('ironic/password').with(:value => ironic_user_password)
        should contain_nova_config('ironic/username').with(:value => ironic_username)
        should contain_nova_config('ironic/project_name').with(:value => ironic_tenant)
        should contain_nova_config('ironic/auth_url').with(:value => "#{admin_uri}/v2.0")
        should contain_nova_config('DEFAULT/compute_driver').with(:value => 'ironic.IronicDriver')
        should contain_nova_config('neutron/auth_url').with(:value => "#{admin_uri}/v3")
        should contain_nova_config('DEFAULT/max_concurrent_builds').with(:value => '50')

        should contain_class('nova::ironic::common').with(
          :auth_url     => "#{admin_uri}/v2.0",
          :username     => ironic_username,
          :project_name => ironic_tenant,
          :password     => ironic_user_password,
          :api_endpoint => "#{ironic_protocol}://#{ironic_endpoint}:6385/v1",
        )

        should contain_class('nova::compute::ironic').with(
          :max_concurrent_builds => 50,
        )
      end

      it 'should properly configure default transport url' do
        should contain_nova_config('DEFAULT/transport_url').with_value(transport_url)
      end

      it 'should configure region name in cinder section' do
         should contain_nova_config('cinder/os_region_name').with_value(region_name)
      end

      it 'nova config should have reserved_host_memory_mb set to 0' do
        should contain_nova_config('DEFAULT/reserved_host_memory_mb').with(:value => '0')
      end

      it 'nova-compute.conf should have host set to "ironic-compute"' do
        should contain_file('/etc/nova/nova-compute.conf').with('content'  => "[DEFAULT]\nhost=ironic-compute")
      end

      it 'nova-compute should manages by pacemaker, and should be disabled as system service' do
        expect(subject).to contain_pcmk_resource('p_nova_compute_ironic').with(
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
        facts[:os_workers] = 8
        max_overflow = Noop.hiera 'max_overflow', [facts[:os_workers] * 5 + 0, 60 + 0].min
        idle_timeout = Noop.hiera 'idle_timeout', '3600'
        max_retries = Noop.hiera 'max_retries', '-1'
        max_pool_size = Noop.hiera 'max_pool_size', [facts[:os_workers] * 5 + 0, 30 + 0].min

        should contain_class('nova').with(
          :database_connection    => "#{nova_db_type}://#{nova_db_user}:#{nova_db_password}@#{database_vip}/#{nova_db_name}#{extra_params}",
          :cinder_catalog_info    => Noop.puppet_function('pick', nova_hash['cinder_catalog_info'], 'volumev2:cinderv2:internalURL'),
          :use_stderr             => use_stderr,
          :notification_driver    => nova_notification_driver,
          :glance_api_servers     => glance_api_servers,
          :database_max_overflow  => max_overflow,
          :database_idle_timeout  => idle_timeout,
          :database_max_retries   => max_retries,
          :database_max_pool_size => max_pool_size,
          :default_transport_url  => transport_url,
        )
        should contain_class('nova::compute').with(
          :allow_resize_to_same_host => Noop.puppet_function('pick', nova_hash['allow_resize_to_same_host'], true)
        )
      end

      let(:default_availability_zone) { Noop.puppet_function 'pick', nova_hash['default_availability_zone'], facts[:os_service_default] }
      let(:default_schedule_zone) { Noop.puppet_function 'pick', nova_hash['default_schedule_zone'], facts[:os_service_default] }

      it 'should configure availability zones' do
        should contain_class('nova::availability_zone').with(
          'default_availability_zone' => default_availability_zone,
          'default_schedule_zone'     => default_schedule_zone,
        )
      end
    end
  end

  test_ubuntu_and_centos manifest
end
