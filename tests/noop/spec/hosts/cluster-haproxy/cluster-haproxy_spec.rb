require 'spec_helper'
require 'shared-examples'
manifest = 'cluster-haproxy/cluster-haproxy.pp'

describe manifest do
  shared_examples 'catalog' do

    networks = []
    endpoints = Noop.hiera_structure 'network_scheme/endpoints'
    management_vip = Noop.hiera 'management_vip'
    endpoints.each{ |k,v|
      if v['IP'].is_a?(Array)
        v['IP'].each { |ip|
          networks << IPAddr.new(ip).to_s + '/' + ip.split('/')[1]
        }
      end
      if v.has_key?('routes') and v['routes'].is_a?(Array)
        v['routes'].each { |route|
          networks << route['net']
        }
      end
    }

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
    it "should not contain stats enable for defaults and global section" do
        should_not contain_concat__fragment('haproxy-base').with_content(
            %r{\n\s*stats\s+enable\s*$\n}
        )
    end

  end

  test_ubuntu_and_centos manifest
end

