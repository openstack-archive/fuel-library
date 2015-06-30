require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should set empty trusts_delegated_roles for neutron auth' do
      contain_class('neutron::keystone::auth')
    end
  end

  test_ubuntu_and_centos manifest
end
