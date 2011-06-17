# compute.pp

resources { 'nova_config':
  purge => true,
}

class { 'nova::ubuntu::compute':
  api_server => '10.0.0.2',
  rabbit_host => '10.0.0.2',
  db_host => '10.0.0.2',
  db_user => 'nova',
  db_password => 'password',
  flat_network_bridge => 'br100',
  flat_network_bridge_ip => '11.0.0.2',
  flat_network_bridge_netmask => '255.255.255.0',
  enabled => 'true',
}
