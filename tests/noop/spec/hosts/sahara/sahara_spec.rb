require 'spec_helper'
require 'shared-examples'
manifest = 'sahara/sahara.pp'

describe manifest do
  shared_examples 'puppet catalogue' do

    settings = Noop.fuel_settings
    use_neutron = settings['quantum'].to_s

    # Sahara
    if settings['sahara']['enabled']
      it 'should declare sahara class correctly' do
        should contain_class('sahara').with(
          'db_password'       => settings['sahara']['db_password'],
          'keystone_password' => settings['sahara']['user_password'],
          'use_neutron'              => use_neutron,
          'rpc_backend'              => 'rabbit',
          'rabbit_ha_queues'         => 'true',
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end

