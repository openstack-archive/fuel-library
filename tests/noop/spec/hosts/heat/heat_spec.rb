require 'spec_helper'
require 'shared-examples'
manifest = 'heat/heat.pp'

describe manifest do
  shared_examples 'catalog' do

    it 'should set empty trusts_delegated_roles for heat authentication and engine' do
      should contain_class('heat::keystone::auth').with(
        'trusts_delegated_roles' => [],
      )
      should contain_class('heat::engine').with(
        'trusts_delegated_roles' => [],
      )
      should contain_heat_config('DEFAULT/trusts_delegated_roles').with(
        'value' => [],
      )
    end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

