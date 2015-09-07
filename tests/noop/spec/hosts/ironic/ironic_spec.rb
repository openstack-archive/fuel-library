require 'spec_helper'
require 'shared-examples'
manifest = 'ironic/ironic.pp'

describe manifest do
  shared_examples 'catalog' do
    rabbit_user = Noop.hiera_structure 'rabbit/user', 'nova'
    rabbit_password = Noop.hiera_structure 'rabbit/password'
    ironic_enabled = Noop.hiera_structure 'ironic/enabled'

    if ironic_enabled
      it 'should declare ironic class correctly' do
        should contain_class('ironic').with(
          'rabbit_userid'   => rabbit_user,
          'rabbit_password' => rabbit_password,
          'enabled_drivers' => ['fuel_ssh'],
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end
