require 'spec_helper'
require 'zlib'
require 'ipaddr'

describe 'default' do
  admin_nets = {"test"=>
    {"rack1"=>
      {"admin"=>
        {"cidr"=>"10.144.0.0/24",
         "ip_ranges"=>[["10.144.0.10", "10.144.0.254"]],
         "gateway"=>"10.144.0.5"}},
     "default"=>
      {"admin"=>
        {"cidr"=>"10.145.0.0/24",
         "ip_ranges"=>[["10.145.0.10", "10.145.0.254"]],
         "gateway"=>"10.145.0.1"}},
     "rack3"=>
      {"admin"=>
        {"cidr"=>"10.146.0.0/24",
         "ip_ranges"=>[["10.146.0.10", "10.146.0.254"]],
         "gateway"=>"10.146.0.5"}}}}
  admin_network  = {"interface"=>"eth0",
    "ipaddress"=>"10.145.0.2",
    "netmask"=>"255.255.255.0",
    "cidr"=>"10.20.0.0/24",
    "size"=>"256",
    "dhcp_pool_start"=>"10.145.0.3",
    "dhcp_pool_end"=>"10.145.0.254",
    "mac"=>"64:42:d3:10:64:68",
    "dhcp_gateway"=>"10.145.0.1"}

  admin_nets.each do |env_name, env|
    env.each do |nodegroup_name, nodegroup|
      next if nodegroup_name == 'default'
      net = nodegroup['admin']
      net['ip_ranges'].each do |ip_range|
        netmask = IPAddr.new('255.255.255.255').mask(net['cidr'].split('/')[1]).to_s
        print_range = ip_range.join('_')
        resource_name = sprintf("range_%08x", Zlib::crc32("#{env_name}_#{nodegroup_name}_#{print_range}").to_i)
        it { should contain_file("/etc/dnsmasq.d/#{resource_name}.conf") \
             .with_content(/^dhcp-range=#{resource_name}.*#{netmask},120m\n|,boothost,#{admin_network['ipaddress']}\n/)
        }
      end
    end
  end

end
