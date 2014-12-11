require 'spec_helper'
require 'shared-examples'
manifest = 'horizon/horizon.pp'

describe manifest do
  shared_examples 'puppet catalogue' do

    settings = Noop.fuel_settings
    horizon_bind_address = Noop.node_hash['internal_address']
    nova_quota = settings['nova_quota']

    it { should compile }

    # Horizon
    it 'should declare openstack::horizon class' do
      should contain_class('openstack::horizon').with(
        'nova_quota'   => nova_quota,
        'bind_address' => horizon_bind_address,
      )
    end

  end
  test_ubuntu_and_centos manifest
end

