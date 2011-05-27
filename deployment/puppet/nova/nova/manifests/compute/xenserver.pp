class nova::compute::xenserver( 
  $enabled = false
  $xenapi_connection_url,
  $xenapi_connection_username,
  $xenapi_connection_password,
  $xenapi_inject_image=false,
) inherits nova {

  class { 'nova::compute':
    enabled => $enabled,
  }

  nova_config { 'xenapi_connection_url':
    value => $xenapi_connection_url,
  }
  nova_config { 'xenapi_connection_username':
    value => $xenapi_connection_username,
  }
  nova_config { 'xenapi_connection_password':
    value => $xenapi_connection_password,
  }
  nova_config { 'xenapi_inject_image':
    value => $xenapi_inject_image,
  }
}
