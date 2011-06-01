class nova::compute::xenserver( 
  # TODO - what does this host do?
  $host,
  $xenapi_connection_url,
  $xenapi_connection_username,
  $xenapi_connection_password,
  $xenapi_inject_image=false
) {

  nova_config {
    'xenapi_connection_url': value => $xenapi_connection_url;
    'xenapi_connection_username': value => $xenapi_connection_username;
    'xenapi_connection_password': value => $xenapi_connection_password;
    'xenapi_inject_image': value => $xenapi_inject_image;
  }
}
