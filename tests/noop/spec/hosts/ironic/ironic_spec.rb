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

      database_vip = Noop.hiera('database_vip')
      ironic_db_password = Noop.hiera_structure 'ironic/db_password', 'ironic'
      ironic_db_user = Noop.hiera_structure 'ironic/db_user', 'ironic'
      ironic_db_name = Noop.hiera_structure 'ironic/db_name', 'ironic'

      it 'should configure default_log_levels' do
        should contain_ironic_config('DEFAULT/default_log_levels').with_value(default_log_levels.sort.join(','))
      end

      it 'should declare ironic class correctly' do
        should contain_class('ironic').with(
          'rabbit_userid'       => rabbit_user,
          'rabbit_password'     => rabbit_password,
          'sync_db'             => primary_controller,
          'control_exchange'    => 'ironic',
          'amqp_durable_queues' => amqp_durable_queues,
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

      # TODO (iberezovskiy): uncomment this test after ironic module update
      #it 'should configure default log levels' do
      #  should contain_class('ironic::logging').with('default_log_levels' => default_log_levels)
      #end
    end
    test_ubuntu_and_centos manifest
  end
end
