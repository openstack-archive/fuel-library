require 'spec_helper'
require 'shared-examples'
manifest = 'sahara/sahara.pp'

describe manifest do
  shared_examples 'catalog' do

    use_neutron = Noop.hiera 'use_neutron'
    enabled = Noop.hiera_structure 'sahara/enabled'
    db_password = Noop.hiera_structure 'sahara/db_password'
    user_password = Noop.hiera_structure 'sahara/user_password'

    # Sahara
    if enabled
      it 'should declare sahara class correctly' do
        facts[:processorcount] = 10
        db_max_pool_size = [facts[:processorcount] * 5 + 0, 30 + 0].min
        db_max_overflow  = [facts[:processorcount] * 5 + 0, 60 + 0].min
        db_max_retries   = '-1'
        db_idle_timeout  = '3600'

        should contain_class('sahara').with(
          'db_password'              => db_password,
          'keystone_password'        => user_password,
          'db_max_pool_size'         => db_max_pool_size,
          'db_max_overflow'          => db_max_overflow,
          'db_max_retries'           => db_max_retries,
          'db_idle_timeout'          => db_idle_timeout,
          'use_neutron'              => use_neutron,
          'rpc_backend'              => 'rabbit',
          'rabbit_ha_queues'         => 'true',
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end

