class nova::all(
  $xenapi_connection_url,
  $xenapi_connection_username,
  $xenapi_connection_password,
  $sql_connection,
  $network_manager,
  $image_service,
  $verbose = 'undef',
  $nodaemon = 'undef',
  $flat_network_bridge = 'xenbr0',
  $connection_type = 'xenapi',
  $xenapi_inject_image = 'false',
  $rescue_timeout = '86400',
  $allow_admin_api = 'true',
  $xenapi_inject_image = 'false',
  $use_ipv6 = 'false',
  $flat_injected = 'true',
  $ipv6_backend = 'account_identifier'
) {

  $novaConfFlags = {
    verbose => $verbose,
    nodaemon => $nodaemon,
    sql_connection => $sql_connetion,
    network_manager => $network_manager,
    image_service => $image_service,
    flat_network_bridge => $flat_network_bridge,
    connection_type => $connection_type,
    xenapi_connection_url => $xenapi_connection_url,
    xenapi_connection_username => $xenapi_connection_username,
    xenapi_connection_password => $xenapi_connection_password,
    xenapi_inject_image => $xenapi_inject_image,
    rescue_timeout => $resuce_timeout,
    allow_admin_api => $allow_admin_api,
    xenapi_inject_image => $xenapi_inject_image,
    use_ipv6 => $use_ipv6,
    flat_injected => $flat_injected,
    ipv6_backend => $ipv6_backend
  }
  class { "nova": novaConfHash => $novaConfFlags }
  class { "nova::api": isServiceEnabled => false }
  class { "nova::compute": isServiceEnabled => false }
  class { "nova::network": isServiceEnabled => false }
  class { "nova::objectstore": isServiceEnabled => false }
  class { "nova::scheduler": isServiceEnabled => false }
}
