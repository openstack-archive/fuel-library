node 'default' {
  $admin_networks = [
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
    # Network id=3 has parameters shared with network id=2
    {"id"=>3,
      "node_group_name"=>"default3",
      "node_group_id"=>23,
      "cluster_name"=>"default3",
      "cluster_id"=>3,
      "cidr"=>"10.144.0.0/24",
      "gateway"=>"10.144.0.5",
      "ip_ranges"=>[["10.144.0.10", "10.144.0.254"]]}]

  $admin_network  = {"interface"=>"eth0",
    "ipaddress"=>"10.145.0.2",
    "netmask"=>"255.255.255.0",
    "cidr"=>"10.20.0.0/24",
    "size"=>"256",
    "dhcp_pool_start"=>"10.145.0.3",
    "dhcp_pool_end"=>"10.145.0.254",
    "mac"=>"64:42:d3:10:64:68",
    "dhcp_gateway"=>"10.145.0.1"}

  Fuel::Dnsmasq::Dhcp_range <||> {
    next_server => $admin_network['ipaddress'],
  }

  file { '/etc/dnsmasq.d':
    ensure  => 'directory',
    recurse => true,
    purge   => true,
  }

  create_dnsmasq_dhcp_ranges($admin_networks, ['default'])
}
