stage { 'repo-setup':
  before => Stage['main'],
}
class { 'apt':
  disable_keys => true, 
  always_apt_update => true,
  stage => 'repo-setup',
}
class { 'nova::repo':
  stage => 'repo-setup',
}
class { 'nova::all':
  verbose => 'undef',
  nodaemon => 'undef',
  sql_connection => 'mysql://root:<password>@127.0.0.1/nova',
  network_manager => 'nova.network.manager.FlatManager',
  image_service => 'nova.image.glance.GlanceImageService',
  flat_network_bridge => 'xenbr0',
  connection_type => 'xenapi',
  xenapi_connection_url => 'https://<XenServer IP>',
  xenapi_connection_username => 'root',
  xenapi_connection_password => 'password',
  xenapi_inject_image => 'false',
  rescue_timeout => '86400',
  allow_admin_api => 'true',
  use_ipv6 => 'false',
  flat_injected => 'true',
  ipv6_backend => 'account_identifier',
}

# this will probably be on its own machine
class mysql::server {
  mysql_root_pw => 'foo',
}

mysql::db { 
  db_user, 
  db_pw, 
  db_charset = 'utf8', 
  host = 'localhost',
  grant='all',
  sql=''
) {
}
