require 'spec_helper'
require 'zlib'
require 'ipaddr'

describe 'default' do
  admin_nets = [
    {"id"=>1,
      "node_group_name"=>nil,
      "node_group_id"=>nil,
      "cluster_name"=>nil,
      "cluster_id"=>nil,
      "cidr"=>"10.145.0.0/24",
      "gateway"=>"10.145.0.2",
      "ip_ranges"=>[["10.145.0.3", "10.145.0.250"]]},
    {"id"=>2,
      "node_group_name"=>"default2",
      "node_group_id"=>22,
      "cluster_name"=>"default2",
      "cluster_id"=>2,
      "cidr"=>"10.144.0.0/24",
      "gateway"=>"10.144.0.5",
      "ip_ranges"=>[["10.144.0.10", "10.144.0.254"]]},
    # Network with parameters shared with id=2
    {"id"=>3,
      "node_group_name"=>"default3",
      "node_group_id"=>23,
      "cluster_name"=>"default3",
      "cluster_id"=>3,
      "cidr"=>"10.144.0.0/24",
      "gateway"=>"10.144.0.5",
      "ip_ranges"=>[["10.144.0.10", "10.144.0.254"]]}
  ]
  admin_network  = {"interface"=>"eth0",
    "ipaddress"=>"10.145.0.2",
    "netmask"=>"255.255.255.0",
    "cidr"=>"10.20.0.0/24",
    "size"=>"256",
    "dhcp_pool_start"=>"10.145.0.3",
    "dhcp_pool_end"=>"10.145.0.254",
    "mac"=>"64:42:d3:10:64:68",
    "dhcp_gateway"=>"10.145.0.1"}

  admin_nets.each do |net|
    net['ip_ranges'].each do |ip_range|
      netmask = IPAddr.new('255.255.255.255').mask(net['cidr'].split('/')[1]).to_s
      print_range = ip_range.join('_')
      resource_name = sprintf("range_%08x", Zlib::crc32("#{print_range}_#{net['cidr']}").to_i)
      it { should contain_file("/etc/dnsmasq.d/#{resource_name}.conf") \
           .with_content(/^dhcp-range=#{resource_name}.*#{netmask},120m\n|,boothost,#{admin_network['ipaddress']}\n/)
      }
      it { should contain_file("/etc/dnsmasq.d/#{resource_name}.conf") \
           .with_content(/^dhcp-match=set:ipxe,175$/)
      }
      it { should contain_file("/etc/dnsmasq.d/#{resource_name}.conf") \
           .with_content(/^dhcp-option-force=tag:ipxe,210,http:/)
      }
    end
  end

end
