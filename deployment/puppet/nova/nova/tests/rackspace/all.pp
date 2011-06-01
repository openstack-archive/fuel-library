Nova_config { target => '/tmp/nova.config' }
resources { 'nova_config':
  purge => true,
}

class { 'nova::rackspace::all':
  image_service => 'nova.image.glance.GlanceImageService',
  glance_host => 'glance_ip_address',
  glance_port => '9292',
  allow_admin_api => 'true',
  host => $ipaddress,
  xenapi_connection_url => 'https://<XenServer_IP>',
  xenapi_connection_username => 'root',
  xenapi_connection_password => 'password',
  xenapi_inject_image => 'false',
  db_password => 'password',
}
