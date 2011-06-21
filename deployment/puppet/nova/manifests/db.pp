class nova::db(
  $password,
  $name = 'nova',
  $user = 'nova',
  $host = '127.0.0.1',
  $allowed_hosts = undef,
  $cluster_id = 'localzone'
) {

  # only start configuring nova after the database is setup
  Mysql::Db[$name] -> Nova_config<| |>

  # now this requires storedconfigs
  # TODO - worry about the security implications
  @@nova_config { 'database_url':
    value => "mysql://${user}:${password}@${host}/${name}",
    tag   => $zone,
  }

  exec { "initial-db-sync":
    command     => "/usr/bin/nova-manage db sync",
    refreshonly => true,
    require     => [Package["nova-common"],Nova_config['sql_connection']]
  }

  mysql::db { $name:
    user         => $user,
    password     => $password,
    host         => $host,
    charset      => 'latin1',
    # I may want to inject some sql
    require      => Class['mysql::server'],
    notify       => Exec["initial-db-sync"],
  }

  if $allowed_hosts {
     nova::db::host_access { $allowed_hosts:
      user      => $user,
      password  => $password,
      database  => $name,
    }
  } else {
    Nova::Db::Host_access<<| tag == $cluster_id |>>
  }
}
