require 'spec_helper'
require 'shared-examples'
manifest = 'ironic/ironic_vips.pp'

describe manifest do
  shared_examples 'catalog' do
    ironic_enabled = Noop.hiera_structure 'ironic/enabled'

    if ironic_enabled
      it do
        expect(subject).to contain_cs_resource('vip__baremetal').with(
                             :ensure => 'present',
                         )
      end

      it do
        expect(subject).to contain_service('vip__baremetal').with(
                             :provider => 'pacemaker',
                             :ensure   => 'running',
                             :enable   => true,
                         )
      end
    end
  end

  test_ubuntu_and_centos manifest
end
