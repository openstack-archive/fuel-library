class openstack_tasks::ironic::db {

  notice('MODULAR: ironic/db.pp')

  $ironic_hash    = hiera_hash('ironic', {})
  $mysql_hash     = hiera_hash('mysql', {})
  $database_vip   = hiera('database_vip')

  $mysql_root_user     = pick($mysql_hash['root_user'], 'root')
  $mysql_db_create     = pick($mysql_hash['db_create'], true)
  $mysql_root_password = $mysql_hash['root_password']

  $db_user     = pick($ironic_hash['db_user'], 'ironic')
  $db_name     = pick($ironic_hash['db_name'], 'ironic')
  $db_password = pick($ironic_hash['db_password'], $mysql_root_password)

  $db_host          = pick($ironic_hash['db_host'], $database_vip)
  $db_create        = pick($ironic_hash['db_create'], $mysql_db_create)
  $db_root_user     = pick($ironic_hash['root_user'], $mysql_root_user)
  $db_root_password = pick($ironic_hash['root_password'], $mysql_root_password)

  $allowed_hosts = [ 'localhost', '127.0.0.1', '%' ]

  validate_string($mysql_root_user)
  validate_string($database_vip)

  if $db_create {
    class { '::openstack::galera::client':
      custom_setup_class => hiera('mysql_custom_setup_class', 'galera'),
    }

    class { '::ironic::db::mysql':
      user          => $db_user,
      password      => $db_password,
      dbname        => $db_name,
      allowed_hosts => $allowed_hosts,
    }

    class { '::osnailyfacter::mysql_access':
      db_host     => $db_host,
      db_user     => $db_root_user,
      db_password => $db_root_password,
    }

    Class['::openstack::galera::client'] ->
      Class['::osnailyfacter::mysql_access'] ->
        Class['::ironic::db::mysql']
  }

}
