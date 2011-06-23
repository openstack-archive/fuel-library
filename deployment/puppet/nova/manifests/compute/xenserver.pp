class nova::compute::xenserver(
  # TODO - what does this host do?
  $host,
  $api_server,
  $xenapi_connection_url,
  $xenapi_connection_username,
  $xenapi_connection_password,
  $xenapi_inject_image=false,
  $network_manager='nova.network.manager.FlatManager',
  $flat_network_bridge='xenbr0',
  $enabled=true
) {

  class { 'nova::compute':
    api_server => $api_server,
    enabled    => $enabled,
  }
  nova_config {
    'connection_type': value => 'xenapi';
    'xenapi_connection_url': value => $xenapi_connection_url;
    'xenapi_connection_username': value => $xenapi_connection_username;
    'xenapi_connection_password': value => $xenapi_connection_password;
    'xenapi_inject_image': value => $xenapi_inject_image;
    'network_manager': value => $network_manager;
    'flat_network_bridge': value => $flat_network_bridge;
  }
  package { 'xenapi':
    ensure   => installed,
    provider => pip
  }
}
