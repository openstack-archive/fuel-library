class nova::all(
  $xenapi_connection_url,
  $xenapi_connection_username,
  $xenapi_connection_password,
  $xenapi_inject_image = 'false',
  $sql_connection,
  $network_manager,
  $image_service,
  $logdir,
  $verbose = 'undef',
  $nodaemon = 'undef',
  $flat_network_bridge = 'xenbr0',
  $connection_type = 'xenapi',
  $rescue_timeout = '86400',
  $allow_admin_api = 'true',
  $xenapi_inject_image = 'false',
  $use_ipv6 = 'false',
  $flat_injected = 'true',
  $ipv6_backend = 'account_identifier'
) {

  class { "nova":
    sql_connection => sql_connection

  }
  class { "nova::api": enabled => false }
  class { "nova::compute": enabled => false }
  class { "nova::network": enabled => false }
  class { "nova::objectstore": enabled => false }
  class { "nova::scheduler": enabled => false }
  class { 'nova::db':
    password => 'password',
    name     => 'nova',
    user     => 'nova',
    host     => 'localhost',
  }
}
