notice('MODULAR: database_virtual_ips')

$role             = hiera('role')
$node             = hiera('node')
$network_metadata = hiera('network_metadata')
$network_scheme   = hiera('network_scheme', {})
$internal_int     = hiera('internal_int')
$public_int       = hiera('public_int')

$vips = pick($network_metadata['vips'], {})

$management_database_vip = $vips['management_database_vip']
$public_database_vip = $vips['public_database_vip']

$internal_netmask = $node[0]['internal_netmask']
$public_netmask = $node[0]['public_netmask']

if 'database' in $role {

  if $management_database_vip {
    $management_database_vip_data = {
      namespace            => 'database',
      nic                  => $internal_int,
      base_veth            => "${internal_int}-db",
      ns_veth              => "db-m",
      ip                   => $management_database_vip,
      cidr_netmask         => netmask_to_cidr($internal_netmask),
      gateway              => 'none',
      gateway_metric       => '0',
      bridge               => $network_scheme['roles']['management'],
      with_ping            => false,
      ping_host_list       => "",
    }

    cluster::virtual_ip { 'management_database' :
      vip => $management_database_vip_data,
    }
  }

  if $public_database_vip {
    $public_database_vip_data = {
      namespace            => 'database',
      nic                  => $public_int,
      base_veth            => "${public_int}-db",
      ns_veth              => "db-p",
      ip                   => $public_database_vip,
      cidr_netmask         => netmask_to_cidr($public_netmask),
      gateway              => 'none',
      gateway_metric       => '0',
      bridge               => $network_scheme['roles']['ex'],
      with_ping            => false,
      ping_host_list       => "",
    }

    cluster::virtual_ip { 'public_database' :
      vip => $public_database_vip_data,
    }
  }

}
