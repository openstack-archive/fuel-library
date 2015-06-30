require 'spec_helper'
require 'shared-examples'
manifest = 'horizon/horizon.pp'

describe manifest do
  shared_examples 'catalog' do

    internal_address = Noop.node_hash['internal_address']
    nova_quota = Noop.hiera 'nova_quota'
    management_vip = Noop.hiera('management_vip')
    keystone_url = "http://#{management_vip}:5000/v2.0"

    # Horizon
    it 'should declare openstack::horizon class' do
      should contain_class('openstack::horizon').with(
        'nova_quota'   => nova_quota,
        'bind_address' => '*',
      )
    end

    it 'should declare openstack::horizon class with keystone_url' do
        should contain_class('openstack::horizon').with('keystone_url' => keystone_url)
    end

  end
  test_ubuntu_and_centos manifest
end

