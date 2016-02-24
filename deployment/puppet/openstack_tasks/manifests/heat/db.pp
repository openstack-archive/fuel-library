class openstack_tasks::heat::db {

  notice('MODULAR: heat/db.pp')

  $heat_hash      = hiera_hash('heat', {})
  $mysql_hash     = hiera_hash('mysql', {})
  $management_vip = hiera('management_vip', undef)
  $database_vip   = hiera('database_vip', undef)

  $mysql_root_user     = pick($mysql_hash['root_user'], 'root')
  $mysql_db_create     = pick($mysql_hash['db_create'], true)
  $mysql_root_password = $mysql_hash['root_password']

  $db_user     = pick($heat_hash['db_user'], 'heat')
  $db_name     = pick($heat_hash['db_name'], 'heat')
  $db_password = pick($heat_hash['db_password'], $mysql_root_password)

  $db_host          = pick($heat_hash['db_host'], $database_vip)
  $db_create        = pick($heat_hash['db_create'], $mysql_db_create)
  $db_root_user     = pick($heat_hash['root_user'], $mysql_root_user)
  $db_root_password = pick($heat_hash['root_password'], $mysql_root_password)

  $allowed_hosts = [ 'localhost', '127.0.0.1', '%' ]

  validate_string($mysql_root_user)

  if $db_create {

    class { '::openstack::galera::client':
      custom_setup_class => hiera('mysql_custom_setup_class', 'galera'),
    }

    class { '::heat::db::mysql':
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
        Class['::heat::db::mysql']

  }

}
