require 'spec_helper'
require 'shared-examples'
manifest = 'murano/murano.pp'

describe manifest do
  shared_examples 'catalog' do
    rabbit_user = Noop.hiera_structure 'rabbit/user', 'nova'
    rabbit_password = Noop.hiera_structure 'rabbit/password'
    use_neutron = Noop.hiera 'use_neutron'
    enabled = Noop.hiera_structure 'murano/enabled'

    if enabled
      it 'should declare murano class correctly' do
        should contain_class('murano').with(
          'murano_os_rabbit_userid' => rabbit_user,
          'murano_os_rabbit_passwd' => rabbit_password,
          'use_neutron'             => use_neutron,
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end

