require 'spec_helper'
require 'shared-examples'
manifest = 'keystone/keystone_secure.pp'
describe manifest do
  shared_examples 'catalog' do
    it "should contain file_line keystone-remove-AdminTokenAuthMiddleware" do
      should contain_file_line('keystone-remove-AdminTokenAuthMiddleware').with(
        'ensure' => 'absent',
        'path'   => '/etc/keystone/keystone-paste.ini',
        'line'   => 'paste.filter_factory = keystone.middleware:AdminTokenAuthMiddleware.factory',
      ).that_notifies('Service[keystone]')
    end
  end # end of shared_examples
  test_ubuntu_and_centos manifest
end

