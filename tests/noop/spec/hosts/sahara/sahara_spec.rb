require 'spec_helper'
require 'shared-examples'
manifest = 'sahara/sahara.pp'

describe manifest do
  shared_examples 'puppet catalogue' do

    use_neutron = Noop.hiera 'use_neutron'
    enabled = Noop.hiera_structure 'sahara/enabled'
    db_password = Noop.hiera_structure 'sahara/db_password'
    user_password = Noop.hiera_structure 'sahara/user_password'

    # Sahara
    if enabled
      it 'should declare sahara class correctly' do
        should contain_class('sahara').with(
          'db_password'              => db_password,
          'keystone_password'        => user_password,
          'use_neutron'              => use_neutron,
          'rpc_backend'              => 'rabbit',
          'rabbit_ha_queues'         => 'true',
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end

