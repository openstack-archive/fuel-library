require 'spec_helper'
require 'shared-examples'
manifest = 'heat/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should set empty trusts_delegated_roles for heat auth' do
      contain_class('heat::keystone::auth').with(
        'trusts_delegated_roles' => [],
      )
    end
  end

  test_ubuntu_and_centos manifest
end
