require 'spec_helper'
require 'shared-examples'
manifest = 'cluster-haproxy/cluster-haproxy.pp'

describe manifest do
  shared_examples 'catalog' do

    networks = []
    endpoints = Noop.hiera_structure 'network_scheme/endpoints'
    management_vip = Noop.hiera 'management_vip'
    filter = nil

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

    it "should delcare cluster::haproxy with other_networks set to #{networks.join(' ')}" do
      should contain_class('cluster::haproxy').with(
        'other_networks' => networks.join(' '),
      )
    end
    it "should contain stats fragment and listen only on lo and #{management_vip}" do
        should contain_concat__fragment('haproxy-stats').with_content(
            %r{\n\s*bind\s+127\.0\.0\.1:10000\s*$\n}
        )
        should contain_concat__fragment('haproxy-stats').with_content(
            %r{\n\s*bind\s+#{management_vip}:10000\s*\n}
        )
    end

  end

  test_ubuntu_and_centos manifest
end
