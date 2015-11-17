require 'spec_helper'
require 'shared-examples'
manifest = 'ironic/ironic.pp'

ironic_enabled = Noop.hiera_structure 'ironic/enabled'
if ironic_enabled

  describe manifest do
    shared_examples 'catalog' do
      rabbit_user = Noop.hiera_structure 'rabbit/user', 'nova'
      rabbit_password = Noop.hiera_structure 'rabbit/password'
      default_log_levels = Noop.hiera_structure 'default_log_levels_hash'

      it 'should declare ironic class correctly' do
        should contain_class('ironic').with(
          'rabbit_userid'   => rabbit_user,
          'rabbit_password' => rabbit_password,
        )
      end

      it 'should configure default log levels' do
        should contain_class('ironic::logging').with('default_log_levels' => default_log_levels)
      end
    end
    test_ubuntu_and_centos manifest
  end
end
