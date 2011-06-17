# cc.pp

resources { 'nova_config':
  purge => true,
}

class { 'mysql::server':
  root_password => 'password'
}

class { 'nova::ubuntu::cc':
  flat_network_bridge => 'br100',
  flat_network_bridge_ip => '11.0.0.1',
  flat_network_bridge_netmask => '255.255.255.0',

  nova_network => '11.0.0.0',
  available_ips => '256',

  image_service => 'nova.image.glance.GlanceImageService',
  glance_host => $ipaddress,

  db_password => 'password',

  db_allowed_hosts => ['somehost', '10.0.0.2', '10.0.0.3'],

  admin_user => 'admin',
  project_name => 'novaproject',
}

class { "glance::api": }
class { "glance::registry":
  sql_connection => "mysql://nova:password@localhost/nova",
}
