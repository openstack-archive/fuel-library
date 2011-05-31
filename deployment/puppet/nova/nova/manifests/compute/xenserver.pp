class nova::compute::xenserver( 
  $host,
  $xenapi_connection_url,
  $xenapi_connection_username,
  $xenapi_connection_password,
  $xenapi_inject_image=false,
  $enabled = false
) inherits nova {

  class { 'nova::compute':
    enabled => $enabled,
  }

  nova_config {
    'xenapi_connection_url': value => $xenapi_connection_url;
    'xenapi_connection_username': value => $xenapi_connection_username;
    'xenapi_connection_password': value => $xenapi_connection_password;
    'xenapi_inject_image': value => $xenapi_inject_image;
  }
}
