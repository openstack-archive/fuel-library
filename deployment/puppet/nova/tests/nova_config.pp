resources { 'nova_config':
  purge => true
}
nova_config { ['verbose', 'nodaemomize']:
  value => 'true',
}
nova_config { 'xenapi_connection_username':
  value => 'rootty',
}
