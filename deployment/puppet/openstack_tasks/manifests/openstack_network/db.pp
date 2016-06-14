class openstack_tasks::openstack_network::db {

  notice('MODULAR: openstack_network/db.pp')

  $neutron_hash   = hiera_hash('quantum_settings', {})
  $mysql_hash     = hiera_hash('mysql', {})
  $management_vip = hiera('management_vip', undef)
  $database_vip   = hiera('database_vip', undef)

  $mysql_root_user     = pick($mysql_hash['root_user'], 'root')
  $mysql_db_create     = pick($mysql_hash['db_create'], true)
  $mysql_root_password = $mysql_hash['root_password']

  $neutron_db = merge($neutron_hash['database'], {})

  $db_user     = pick($neutron_db['db_user'], 'neutron')
  $db_name     = pick($neutron_db['db_name'], 'neutron')
  $db_password = pick($neutron_db['passwd'], $mysql_root_password)

  $db_host          = pick($neutron_db['db_host'], $database_vip)
  $db_create        = pick($neutron_db['db_create'], $mysql_db_create)
  $db_root_user     = pick($neutron_db['root_user'], $mysql_root_user)
  $db_root_password = pick($neutron_db['root_password'], $mysql_root_password)

  $allowed_hosts = [ 'localhost', '127.0.0.1', '%' ]

  validate_string($mysql_root_user)

  if $db_create {

    class { '::openstack::galera::client':
      custom_setup_class => hiera('mysql_custom_setup_class', 'galera'),
    }

    class { '::neutron::db::mysql':
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
    Class['::neutron::db::mysql']

  }

}
