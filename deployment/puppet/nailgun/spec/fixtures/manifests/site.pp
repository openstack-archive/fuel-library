node 'default' {
  $admin_networks = {"test"=>
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
  $admin_network  = {"interface"=>"eth0",
    "ipaddress"=>"10.145.0.2",
    "netmask"=>"255.255.255.0",
    "cidr"=>"10.20.0.0/24",
    "size"=>"256",
    "dhcp_pool_start"=>"10.145.0.3",
    "dhcp_pool_end"=>"10.145.0.254",
    "mac"=>"64:42:d3:10:64:68",
    "dhcp_gateway"=>"10.145.0.1"}

  Nailgun::Dnsmasq::Dhcp_range <||> {
    next_server => $admin_network['ipaddress'],
  }

  file { '/etc/dnsmasq.d':
    ensure  => 'directory',
    recurse => true,
    purge   => true,
  }

  create_dnsmasq_dhcp_ranges($admin_networks, ['default'])
}
