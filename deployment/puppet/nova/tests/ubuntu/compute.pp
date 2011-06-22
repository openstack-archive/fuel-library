# compute.pp

resources { 'nova_config':
  purge => true,
}

class { 'nova::ubuntu::compute':
  api_server => '10.0.0.4',
  rabbit_host => '10.0.0.4',
  db_host => '10.0.0.4',
  db_user => 'nova',
  db_password => 'password',

  image_service => 'nova.image.glance.GlanceImageService',
  glance_api_servers => '10.0.0.4:9292',

  flat_network_bridge => 'br100',
  flat_network_bridge_ip => '11.0.0.2',
  flat_network_bridge_netmask => '255.255.255.0',
  enabled => 'true',
}
