require 'spec_helper'
require 'shared-examples'
manifest = 'database/database.pp'

describe manifest do
  shared_examples 'catalog' do
    networks = []
    network_type = 'br-mgmt'
    endpoints = Noop.hiera_structure 'network_scheme/endpoints'
    
    endpoints.each{ |k,v|
      if k == network_type and v['IP'].is_a?(Array)
        v['IP'].each { |ip|
          networks << IPAddr.new(ip).to_s + '/' + ip.split('/')[1]
        }
      end
      if k == network_type and v.has_key?('routes') and v['routes'].is_a?(Array)
        v['routes'].each { |route|
          networks << route['net']
        }
      end
    }

#    it 'should declare class openstack::db::mysql' do
#      should contain_class('openstack::db::mysql')
#    end
  end
  test_ubuntu_and_centos manifest
end

