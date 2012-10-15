# cc.pp

resources { 'nova_config':
  purge => true,
}

class { 'mysql::server':
  config_hash => { 'bind_address' => $ipaddress_eth0 }
}

class { 'nova::ubuntu::cc':
  flat_network_bridge => 'br100',
  flat_network_bridge_ip => '11.0.0.1',
  flat_network_bridge_netmask => '255.255.255.0',

  nova_network => '11.0.0.0/24',
  available_ips => '256',

  image_service => 'nova.image.glance.GlanceImageService',
  glance_api_servers => "${ipaddress}:9292",
  db_password => 'password',

  db_allowed_hosts => ['somehost', '10.0.0.2', '10.0.0.3', '10.0.0.5', '192.168.25.11'],

  admin_user => 'admin',
  project_name => 'novaproject',
}

class { "glance::api":
  verbose => 'true',
  debug => 'true',
}
class { "glance::registry":
  log_verbose => 'true',
  log_debug => 'true',
  sql_connection => "mysql://nova:password@localhost/nova",
}
