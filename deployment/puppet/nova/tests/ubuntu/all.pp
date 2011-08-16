#Nova_config { target => '/tmp/nova.config' }
resources { 'nova_config':
  purge => true,
}

class { 'mysql::server':
  config_hash => {'bind_address' => '127.0.0.1'}
}

class { 'nova::ubuntu::all':
  flat_network_bridge => 'br100',
  flat_network_bridge_ip => '11.0.0.1',
  flat_network_bridge_netmask => '255.255.255.0',

  nova_network => '11.0.0.0/24',
  available_ips => '256',

  db_password => 'password',

  admin_user => 'admin',
  project_name => 'novaproject',
}
