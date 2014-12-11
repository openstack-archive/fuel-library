require 'spec_helper'
require 'shared-examples'
manifest = 'murano/murano.pp'

describe manifest do
  shared_examples 'puppet catalogue' do
    settings = Noop.fuel_settings
    rabbit_user = settings['rabbit']['user'] || 'nova'
    use_neutron = settings['quantum'].to_s

    if settings['murano']['enabled']
      it 'should declare murano class correctly' do
        should contain_class('murano').with(
          'murano_os_rabbit_userid' => rabbit_user,
          'murano_os_rabbit_passwd' => settings['rabbit']['password'],
          'use_neutron'             => use_neutron,
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end

