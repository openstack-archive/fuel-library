server              = '10.0.0.100'

domain_name         = 'mirantis.com'
name_server         = '10.0.0.100'
next_server         = '10.0.0.100'

dhcp_start_address  = '10.0.0.201'
dhcp_end_address    = '10.0.0.254'
dhcp_netmask        = '255.255.255.0'
dhcp_gateway        = '10.0.0.100'

cobbler_user        = 'cobbler'
cobbler_password    = 'cobbler'

pxetimeout          = '0'


node fuel-01 {
  class { cobbler::server:
    server              => $server,

    domain_name         => $domain_name,
    name_server         => $name_server,
    next_server         => $next_server,

    dhcp_start_address  => $dhcp_start_address,
    dhcp_end_address    => $dhcp_end_address,
    dhcp_netmask        => $dhcp_netmask,
    dhcp_gateway        => $dhcp_gateway,

    cobbler_user        => $cobbler_user,
    cobbler_password    => $cobbler_password ,

    pxetimeout          => $pxetimeout,
  }
}
