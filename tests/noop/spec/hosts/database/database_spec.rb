require 'spec_helper'
require 'shared-examples'
manifest = 'database/database.pp'

describe manifest do
  shared_examples 'catalog' do
    networks = []
    endpoints = Noop.hiera_structure 'network_scheme/endpoints'
    filter = 'br-mgmt'

    class IPAddr
      def mask_length
        @mask_addr.to_s(2).count '1'
      end

      def cidr
        "#{to_s}/#{mask_length}"
      end
    end

    endpoints.each do |interface, parameters|
      next unless parameters.has_key? 'IP' and parameters['IP'].is_a? Array
      next if filter and interface != filter
      parameters['IP'].each do |ip|
        next unless ip
        networks << IPAddr.new(ip).cidr
      end
      next unless parameters.has_key? 'routes' and parameters['routes'].is_a? Array
      parameters['routes'].each do |route|
        next unless route.has_key? 'net'
        networks << IPAddr.new(route['net']).cidr
      end
    end

    it "should delcare osnailyfacter::mysql_root with other_networks set to 240.0.0.2 240.0.0.6 #{networks.join(' ')}" do
      should contain_class('osnailyfacter::mysql_root').with(
        'other_networks' => "240.0.0.2 240.0.0.6 " + networks.join(' '),
      )
    end

    it "should delcare mysql::server" do
      should contain_class('mysql::server')
    end

    it "should delcare osnailyfacter::mysql_access" do
      should contain_class('osnailyfacter::mysql_access')
    end

    it "should delcare openstack::galera::status" do
      should contain_class('openstack::galera::status')
    end

  end

  test_ubuntu_and_centos manifest
end

