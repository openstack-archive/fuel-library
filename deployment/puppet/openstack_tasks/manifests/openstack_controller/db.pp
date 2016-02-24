class openstack_tasks::openstack_controller::db {

  notice('MODULAR: openstack_controller/db.pp')

  $nova_hash      = hiera_hash('nova', {})
  $mysql_hash     = hiera_hash('mysql', {})
  $management_vip = hiera('management_vip', undef)
  $database_vip   = hiera('database_vip', undef)

  $mysql_root_user     = pick($mysql_hash['root_user'], 'root')
  $mysql_db_create     = pick($mysql_hash['db_create'], true)
  $mysql_root_password = $mysql_hash['root_password']

  $db_user         = pick($nova_hash['db_user'], 'nova')
  $db_name         = pick($nova_hash['db_name'], 'nova')
  $db_password     = pick($nova_hash['db_password'], $mysql_root_password)
  $api_db_user     = pick($nova_hash['db_user'], 'nova_api')
  $api_db_name     = pick($nova_hash['db_name'], 'nova_api')
  $api_db_password = pick($nova_hash['api_db_password'], $nova_hash['db_password'], $mysql_root_password)

  $db_host          = pick($nova_hash['db_host'], $database_vip)
  $db_create        = pick($nova_hash['db_create'], $mysql_db_create)
  $db_root_user     = pick($nova_hash['root_user'], $mysql_root_user)
  $db_root_password = pick($nova_hash['root_password'], $mysql_root_password)

  $allowed_hosts = [ 'localhost', '127.0.0.1', '%' ]

  validate_string($mysql_root_user)

  if $db_create {

    class { '::openstack::galera::client':
      custom_setup_class => hiera('mysql_custom_setup_class', 'galera'),
    }

    class { '::nova::db::mysql':
      user          => $db_user,
      password      => $db_password,
      dbname        => $db_name,
      allowed_hosts => $allowed_hosts,
    }

    class { '::nova::db::mysql_api':
      user          => $api_db_user,
      password      => $api_db_password,
      dbname        => $api_db_name,
      allowed_hosts => $allowed_hosts,
    }

    class { '::osnailyfacter::mysql_access':
      db_host     => $db_host,
      db_user     => $db_root_user,
      db_password => $db_root_password,
    }

    Class['::openstack::galera::client'] ->
      Class['::osnailyfacter::mysql_access'] ->
        Class['::nova::db::mysql']

  }

}
