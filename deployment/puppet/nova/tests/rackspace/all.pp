/*
This test should configure everything needed to run openstack on a compute vm running
on a xenserver.
*/

Nova_config { target => '/etc/nova/nova.conf' }
resources { 'nova_config':
  purge => true,
}

class { 'nova::rackspace::all':
  image_service => 'nova.image.glance.GlanceImageService',
  glance_api_servers => "${ipaddress}:9292",
  allow_admin_api => 'true',
  host => $hostname,
  xenapi_connection_url => 'https://<XenServer_IP>',
  xenapi_connection_username => 'root',
  xenapi_connection_password => 'password',
  xenapi_inject_image => 'false',
  db_password => 'password',
}

class { 'glance::api':
  swift_store_user => 'foo_user',
  swift_store_key => 'foo_pass',
}

class { 'glance::registry': }
