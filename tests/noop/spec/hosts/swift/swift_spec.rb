# TODO: DEPRECATED
require 'spec_helper'
require 'shared-examples'
manifest = 'swift/swift.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should contain storage and proxy tasks' do
      should contain_class('openstack_tasks::swift::storage')
      should contain_class('openstack_tasks::swift::proxy')
    end
  end

  test_ubuntu_and_centos manifest
end

