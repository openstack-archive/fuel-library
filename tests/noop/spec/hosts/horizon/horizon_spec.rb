require 'spec_helper'
require 'shared-examples'
manifest = 'horizon/horizon.pp'

describe manifest do
  shared_examples 'catalog' do

    internal_address = Noop.node_hash['internal_address']
    nova_quota = Noop.hiera 'nova_quota'

    # Horizon
    it 'should declare openstack::horizon class' do
      should contain_class('openstack::horizon').with(
        'nova_quota'   => nova_quota,
        'bind_address' => '*',
      )
    end

  end
  test_ubuntu_and_centos manifest
end

