class glance (
  $verbose = 'false',
  $default_store = 'file',
  $bind_port = '9292',
  $registry_port = '9191',
  $auth_domain = '127.0.0.1',
  $swift_store_user,
  $swift_store_key
  $db_user,
  $db_password,
  $glance_ip
) {
  file { '/etc/glance/glance.conf':
    content => template('glance/glance.conf.erb'),
  }
}
