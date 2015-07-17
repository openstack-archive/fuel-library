require 'spec_helper'
require 'shared-examples'
manifest = 'roles/ironic-compute.pp'

describe manifest do
  shared_examples 'catalog' do
    nova_user_password = Noop.hiera_structure 'nova/user_password'
    ironic_enabled = Noop.hiera_structure 'ironic/enabled'

    if ironic_enabled
      it 'nova config should have correct nova_user_password' do
        should contain_nova_config('DEFAULT/nova_user_password').with(
          'nova_user_password' => nova_user_password,
        )
      end

      it 'nova config should have reserved_host_memory set to 0' do
        should contain_nova_config('DEFAULT/reserved_host_memory').with(
          'reserved_host_memory' => '0',
        )
      end
    end
  end

  test_ubuntu_and_centos manifest
end
