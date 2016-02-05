require 'spec_helper'
require 'shared-examples'
manifest = 'virtual_ips/public_vip_ping.pp'

describe manifest do
  shared_examples 'catalog' do

    let (:ping_host) {
      ping_host = task.hiera_structure('network_scheme/endpoints/br-ex/gateway')
      raise 'Could not get the ping host!' unless ping_host
      ping_host
    }

    it do
      expect(subject).to contain_cluster__virtual_ip_ping('vip__public').with(
                             :name      => "vip__public",
                             :host_list => ping_host,
                         )
    end

    it do
      expect(subject).to contain_cs_resource('ping_vip__public').with(
                             :name            => "ping_vip__public",
                             :ensure          => "present",
                             :primitive_class => "ocf",
                             :provided_by     => "pacemaker",
                             :primitive_type  => "ping",
                             :parameters      => {"host_list"=>ping_host, "multiplier"=>"1000", "dampen"=>"30s", "timeout"=>"3s"},
                             :operations      => {"monitor"=>{"interval"=>"20", "timeout"=>"30"}},
                             :complex_type    => "clone",
                             :before          => "Cs_rsc_location[loc_ping_vip__public]",
                         )
    end

    it do
      expect(subject).to contain_service('ping_vip__public').with(
                             :name     => "ping_vip__public",
                             :ensure   => "running",
                             :enable   => true,
                             :provider => "pacemaker",
                         )
    end

    it do
      expect(subject).to contain_cs_rsc_location('loc_ping_vip__public').with(
                             :name      => "loc_ping_vip__public",
                             :primitive => "vip__public",
                             :cib       => "ping_vip__public",
                             :before    => "Service[ping_vip__public]",
                         )
    end


  end

  test_ubuntu_and_centos manifest
end
