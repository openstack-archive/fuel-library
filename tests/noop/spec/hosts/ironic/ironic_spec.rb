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

      let(:max_pool_size) { Noop.hiera('max_pool_size') }
      let(:max_overflow) { Noop.hiera('max_overflow') }
      let(:max_retries) { Noop.hiera('max_retries') }
      let(:idle_timeout) { Noop.hiera('idle_timeout') }

      it 'should configure default_log_levels' do
        should contain_ironic_config('DEFAULT/default_log_levels').with_value(default_log_levels.sort.join(','))
      end

      it 'should declare ironic class correctly' do
        should contain_class('ironic').with(
          'rabbit_userid'   => rabbit_user,
          'rabbit_password' => rabbit_password,
          'sync_db'         => primary_controller,
        )
      end

      it 'should configure database config' do
        should contain_class('ironic').with(
          # TODO(aschultz): fix when supported by ironic module
          #'database_max_pool_size' => max_pool_size,
          #'database_max_overflow' => max_overflow,
          'database_max_retries' => max_retries,
          'database_idle_timeout' => idle_timeout)
      end

      # TODO (iberezovskiy): uncomment this test after ironic module update
      #it 'should configure default log levels' do
      #  should contain_class('ironic::logging').with('default_log_levels' => default_log_levels)
      #end
    end
    test_ubuntu_and_centos manifest
  end
end
