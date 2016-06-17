# ROLE: primary-controller
# ROLE: controller
require 'spec_helper'
require 'shared-examples'
manifest = 'ironic/ironic.pp'


ironic_enabled = Noop.hiera_structure 'ironic/enabled'
if ironic_enabled

  describe manifest do
    shared_examples 'catalog' do
      rabbit_user = Noop.hiera_structure 'rabbit/user', 'nova'
      rabbit_password = Noop.hiera_structure 'rabbit/password'
      default_log_levels_hash = Noop.hiera_hash 'default_log_levels'
      default_log_levels = Noop.puppet_function 'join_keys_to_values',default_log_levels_hash,'='
      primary_controller = Noop.hiera 'primary_controller'
      amqp_durable_queues = Noop.hiera_structure 'ironic/amqp_durable_queues', 'false'
      admin_tenant = Noop.hiera_structure('ironic/tenant', 'services')
      admin_user = Noop.hiera_structure('ironic/auth_name', 'ironic')
      admin_password = Noop.hiera_structure('ironic/user_password', 'ironic')

      database_vip = Noop.hiera('database_vip')
      ironic_db_password = Noop.hiera_structure 'ironic/db_password', 'ironic'
      ironic_db_user = Noop.hiera_structure 'ironic/db_user', 'ironic'
      ironic_db_name = Noop.hiera_structure 'ironic/db_name', 'ironic'

      ironic_hash = Noop.hiera_structure 'ironic', {}
      rabbit_hash = Noop.hiera_structure 'rabbit', {}

      service_endpoint = Noop.hiera 'service_endpoint'
      management_vip = Noop.hiera 'management_vip'
      public_vip = Noop.hiera 'public_vip'
      let(:ssl_hash) { Noop.hiera_hash 'use_ssl', {} }
      let(:public_ssl_hash) { Noop.hiera_hash 'public_ssl', {} }
      let(:internal_auth_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','protocol','http' }
      let(:internal_auth_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','hostname',[service_endpoint, management_vip] }
      let(:internal_auth_url) do
          "#{internal_auth_protocol}://#{internal_auth_address}:5000"
      end
      let(:admin_auth_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin','protocol','http' }
      let(:admin_auth_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin','hostname', [service_endpoint, management_vip] }
      let(:admin_auth_uri) do
          "#{admin_auth_protocol}://#{admin_auth_address}:35357"
      end
      let(:public_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,public_ssl_hash,'ironic','admin','protocol','http' }
      let(:public_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,public_ssl_hash,'ironic','admin','hostname', public_vip }
      let(:neutron_endpoint_default) {Noop.hiera 'neutron_endpoint', management_vip }
      let(:neutron_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'neutron','internal','protocol','http' }
      let(:neutron_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'neutron','internal','hostname', neutron_endpoint_default }

      rabbit_heartbeat_timeout_threshold = Noop.puppet_function 'pick', ironic_hash['rabbit_heartbeat_timeout_threshold'], rabbit_hash['heartbeat_timeout_treshold'], 60
      rabbit_heartbeat_rate = Noop.puppet_function 'pick', ironic_hash['rabbit_heartbeat_rate'], rabbit_hash['heartbeat_rate'], 2

      it 'should configure RabbitMQ Heartbeat parameters' do
        should contain_ironic_config('oslo_messaging_rabbit/heartbeat_timeout_threshold').with_value(rabbit_heartbeat_timeout_threshold)
        should contain_ironic_config('oslo_messaging_rabbit/heartbeat_rate').with_value(rabbit_heartbeat_rate)
      end

      it 'should configure default_log_levels' do
        should contain_ironic_config('DEFAULT/default_log_levels').with_value(default_log_levels.sort.join(','))
      end

      it 'should declare ironic class correctly' do
        should contain_class('ironic').with(
          'rabbit_userid'        => rabbit_user,
          'rabbit_password'      => rabbit_password,
          'sync_db'              => primary_controller,
          'control_exchange'     => 'ironic',
          'amqp_durable_queues'  => amqp_durable_queues,
          'database_max_retries' => '-1',
        )
      end

      it 'should declare ironic::api class correctly' do
        should contain_class('ironic::api').with(
          'auth_uri'             => internal_auth_url,
          'identity_uri'         => admin_auth_uri,
          'admin_tenant_name'    => admin_tenant,
          'admin_user'           => admin_user,
          'admin_password'       => admin_password,
          'neutron_url'          => "#{neutron_protocol}://#{neutron_address}:9696",
          'public_endpoint'      => "#{public_protocol}://#{public_address}:6385"
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

      it 'should configure kombu compression' do
        kombu_compression = Noop.hiera 'kombu_compression', facts[:os_service_default]
        should contain_ironic_config('oslo_messaging_rabbit/kombu_compression').with(:value => kombu_compression)
      end

    end # end of shared_examples
    test_ubuntu_and_centos manifest
  end
end
