# RUN: neut_vlan.ceph.ceil-primary-controller.overridden_ssl ubuntu
# RUN: neut_vlan.ceph.controller-ephemeral-ceph ubuntu
# RUN: neut_vlan.ironic.controller ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-controller ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl ubuntu

require 'spec_helper'
require 'shared-examples'
manifest = 'virtual_ips/public_vip_ping.pp'

describe manifest do
  shared_examples 'catalog' do
    run_ping_checker = Noop.hiera 'run_ping_checker', true
    primary_controller = Noop.hiera 'primary_controller'

    context 'in pinger is enabled on the primary controller', :if => (run_ping_checker and primary_controller) do

      let (:ping_host) {
        ping_host = Noop.hiera_structure('network_scheme/endpoints/br-ex/gateway')
        raise 'Could not get the ping host!' unless ping_host
        ping_host
      }

      it do
        expect(subject).to contain_cluster__virtual_ip_ping('vip__public').with(
                               :name => "vip__public",
                               :host_list => ping_host,
                           )
      end

      it do
        expect(subject).to contain_pcmk_resource('ping_vip__public').with(
                               :name => "ping_vip__public",
                               :ensure => "present",
                               :primitive_class => "ocf",
                               :primitive_provider => "pacemaker",
                               :primitive_type => "ping",
                               :parameters => {"host_list" => ping_host, "multiplier" => "1000", "dampen" => "30s", "timeout" => "3s"},
                               :operations => {"monitor" => {"interval" => "20", "timeout" => "30"}},
                               :complex_type => "clone",
                               :before => ["Pcmk_location[loc_ping_vip__public]", "Service[ping_vip__public]"],
                           )
      end

      it do
        expect(subject).to contain_service('ping_vip__public').with(
                               :name => "ping_vip__public",
                               :ensure => "running",
                               :enable => true,
                               :provider => "pacemaker",
                           )
      end

      it do
        expect(subject).to contain_pcmk_location('loc_ping_vip__public').with(
                               :name => "loc_ping_vip__public",
                               :primitive => "vip__public",
                               :before => "Service[ping_vip__public]",
                           )
      end

    end
  end

  test_ubuntu_and_centos manifest
end
