require 'spec_helper'
require 'shared-examples'
manifest = 'ceilometer/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should set empty trusts_delegated_roles for ceilometer auth' do
      contain_class('ceilometer::keystone::auth')
    end
  end

  test_ubuntu_and_centos manifest
end
