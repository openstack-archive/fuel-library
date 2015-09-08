require 'spec_helper'
require 'shared-examples'
manifest = 'roles/ironic-compute.pp'

describe manifest do
  shared_examples 'catalog' do
    ironic_user_password = Noop.hiera_structure 'ironic/user_password'
    ironic_enabled = Noop.hiera_structure 'ironic/enabled'

    if ironic_enabled
      it 'nova config should have correct nova_user_password' do
        should contain_nova_config('ironic/admin_password').with(:value => ironic_user_password)
        should contain_nova_config('DEFAULT/compute_driver').with(:value => 'ironic.IronicDriver')
      end

      it 'nova config should have reserved_host_memory_mb set to 0' do
        should contain_nova_config('DEFAULT/reserved_host_memory_mb').with(:value => '0')
      end
    end
  end

  test_ubuntu_and_centos manifest
end
