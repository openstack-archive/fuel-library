require 'spec_helper'
require 'shared-examples'
manifest = 'cluster-vrouter/cluster-vrouter.pp'

describe manifest do
  shared_examples 'puppet catalogue' do
    settings = Noop.fuel_settings
    networks = []
    settings['network_scheme']['endpoints'].each{ |k,v|
      if v['IP'].is_a?(Array)
        v['IP'].each { |ip|
          networks << IPAddr.new(ip).to_s + "/" + ip.split('/')[1]
        }
      end
      if v.has_key?('routes') and v['routes'].is_a?(Array)
        v['routes'].each { |route|
          networks << route['net']
        }
      end
    }

    it "should declare class cluster::namespace_ocf" do
      should contain_cluster__namespace_ocf('vrouter').with(
        'host_ip'        => '240.0.0.5',
        'namespace_ip'   => '240.0.0.6',
        'other_networks' => networks.join(' '),
      ).that_comes_before('Class[cluster::haproxy]')
    end

  end

  test_ubuntu_and_centos manifest
end

