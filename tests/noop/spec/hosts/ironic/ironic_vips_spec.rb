require 'spec_helper'
require 'shared-examples'
manifest = 'ironic/ironic_vips.pp'

describe manifest do
  shared_examples 'catalog' do
    interfaces = %w(baremetal baremetal_vrouter)
    vip_interfaces = interfaces.map { |interface| "vip__#{interface}" }
    let (:interfaces) { interfaces }
    let (:vip_interfaces) { vip_interfaces }
    ironic_enabled = Noop.hiera_structure 'ironic/enabled'

    if ironic_enabled
      vip_interfaces.each do |interface|
        it do
          expect(subject).to contain_cs_resource(interface).with(
                               :ensure => 'present',
                           )
        end

        it do
          expect(subject).to contain_service(interface).with(
                               :provider => 'pacemaker',
                               :ensure   => 'running',
                               :enable   => true,
                           )
        end
      end
    end
  end

  test_ubuntu_and_centos manifest
end
