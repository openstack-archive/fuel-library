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
      admin_tenant = Noop.hiera_structure('ironic_hash/tenant', 'services')
      admin_user = Noop.hiera_structure('ironic_hash/user', 'ironic')
      admin_password = Noop.hiera_structure('ironic_hash/user_password')

      database_vip = Noop.hiera('database_vip')
      ironic_db_password = Noop.hiera_structure 'ironic/db_password', 'ironic'
      ironic_db_user = Noop.hiera_structure 'ironic/db_user', 'ironic'
      ironic_db_name = Noop.hiera_structure 'ironic/db_name', 'ironic'

      service_endpoint = Noop.hiera 'service_endpoint'
      management_vip = Noop.hiera 'management_vip'
      let(:ssl_hash) { Noop.hiera_hash 'use_ssl', {} }
      let(:internal_auth_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','protocol','http' }
      let(:internal_auth_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','hostname',[service_endpoint, management_vip] }
      let(:internal_auth_url) do
          "#{internal_auth_protocol}://#{internal_auth_address}:5000"
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
          'aut_uri'              => internal_auth_url,
          'admin_tenant_name'    => admin_tenant_name,
          'admin_user'           => admin_user,
          'admin_password'       => admin_password
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

      it 'should configure default log levels' do
        should contain_class('ironic::logging').with('default_log_levels' => default_log_levels)
      end
    end
    test_ubuntu_and_centos manifest
  end
end
