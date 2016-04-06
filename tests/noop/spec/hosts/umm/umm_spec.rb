# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'umm/umm.pp'

describe manifest do
  shared_examples 'catalog' do
    role = Noop.hiera 'role'
    it 'ensures fuel-umm installed and /etc/umm.conf is present' do
      if role == 'primary-controller' or role == 'controller'
        should contain_package('fuel-umm')
        should contain_file('umm_config').with(
          'ensure' => 'present',
          'path'   => '/etc/umm.conf',
        )
      end
    end
  end # end of shared_examples
  test_ubuntu_and_centos manifest
end

