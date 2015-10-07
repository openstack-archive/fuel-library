require 'spec_helper'
require 'shared-examples'
manifest = 'ironic/ironic.pp'

ironic_enabled = Noop.hiera_structure 'ironic/enabled'
if ironic_enabled

  describe manifest do
    shared_examples 'catalog' do
      rabbit_user = Noop.hiera_structure 'rabbit/user', 'nova'
      rabbit_password = Noop.hiera_structure 'rabbit/password'

        it 'should declare ironic class correctly' do
          should contain_class('ironic').with(
            'rabbit_userid'   => rabbit_user,
            'rabbit_password' => rabbit_password,
          )
        end
      end
    test_ubuntu_and_centos manifest
  end
end
