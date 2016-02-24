class openstack_tasks::murano::db {

  notice('MODULAR: murano/db.pp')

  $node_name      = hiera('node_name')
  $murano_hash    = hiera_hash('murano', {})
  $murano_enabled = pick($murano_hash['enabled'], false)
  $mysql_hash     = hiera_hash('mysql', {})
  $management_vip = hiera('management_vip', undef)
  $database_vip   = hiera('database_vip')

  $mysql_root_user     = pick($mysql_hash['root_user'], 'root')
  $mysql_db_create     = pick($mysql_hash['db_create'], true)
  $mysql_root_password = $mysql_hash['root_password']

  $db_user     = pick($murano_hash['db_user'], 'murano')
  $db_name     = pick($murano_hash['db_name'], 'murano')
  $db_password = pick($murano_hash['db_password'], $mysql_root_password)

  $db_host          = pick($murano_hash['db_host'], $database_vip)
  $db_create        = pick($murano_hash['db_create'], $mysql_db_create)
  $db_root_user     = pick($murano_hash['root_user'], $mysql_root_user)
  $db_root_password = pick($murano_hash['root_password'], $mysql_root_password)

  $allowed_hosts = [ $node_name, 'localhost', '127.0.0.1', '%' ]

  validate_string($mysql_root_user)

  if $murano_enabled and $db_create {

    class { '::openstack::galera::client':
      custom_setup_class => hiera('mysql_custom_setup_class', 'galera'),
    }

    class { '::murano::db::mysql':
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
        Class['::murano::db::mysql']

  }

}
