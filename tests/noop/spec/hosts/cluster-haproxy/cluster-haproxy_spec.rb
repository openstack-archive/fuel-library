require 'spec_helper'
require 'shared-examples'
manifest = 'cluster-haproxy/cluster-haproxy.pp'

describe manifest do
  shared_examples 'catalog' do

    networks = []
    endpoints = Noop.hiera_structure 'network_scheme/endpoints'
    endpoints.each{ |k,v|
      if v['IP'].is_a?(Array)
        v['IP'].each { |ip|
          networks << IPAddr.new(ip).to_s + '/' + ip.split('/')[1]
        }
      end
    }

    it "should delcare cluster::haproxy with other_networks set to #{networks.join(' ')}" do
      should contain_class('cluster::haproxy').with(
        'other_networks' => networks.join(' '),
      )
    end

  end

  test_ubuntu_and_centos manifest
end

