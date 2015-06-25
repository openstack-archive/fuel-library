require 'spec_helper'
require 'shared-examples'
manifest = 'dns/dns-server.pp'

describe manifest do
  shared_examples 'catalog' do

    master_ip = Noop.hiera 'master_ip'
    primary_controller = Noop.hiera 'primary_controller'
    external_dns = Noop.hiera 'external_dns'
    dns_list = external_dns['dns_list'].split(',').compact.collect(&:strip) 

    it "should contain osnailyfacter::dnsmasq" do
      should contain_class('osnailyfacter::dnsmasq').with(
        'external_dns' => dns_list,
        'master_ip'    => master_ip,
      ).that_comes_before('Class[cluster::dns_ocf]')
    end

    it "should contain cluster::dns_ocf" do
      should contain_class('cluster::dns_ocf').with(
        'primary_controller' => primary_controller,
      )
    end

  end

  test_ubuntu_and_centos manifest
end

