require 'spec_helper'
require 'shared-examples'
manifest = 'virtual_ips/virtual_ips.pp'

describe manifest do
  shared_examples 'puppet catalogue' do
    interfaces = %w(public management public_vrouter management_vrouter)
    vip_interfaces = interfaces.map { |interface| "vip__#{interface}" }
    let (:interfaces) { interfaces }
    let (:vip_interfaces) { vip_interfaces }

    it do
      expect(subject).to contain_file('ns-ipaddr2-ocf').with(
                             :path => '/usr/lib/ocf/resource.d/fuel/ns_IPaddr2',
                         )
    end

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

    it do
      should contain_cs_rsc_colocation('vip__public_vrouter-with-vip__management_vrouter').with(
                 :primitives => %w(vip__public_vrouter vip__management_vrouter),
             )
    end

  end

  test_ubuntu_and_centos manifest
end

