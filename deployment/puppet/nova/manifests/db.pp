class nova::db(
  $password,
  $name = 'nova',
  $user = 'nova',
  $host = '127.0.0.1',
  $allowed_hosts = undef,
  $cluster_id = 'localzone'
) {

  # Create the db instance before nova-common if its installed
  Mysql::Db[$name] -> Package<| title == "nova-common" |>

  # now this requires storedconfigs
  # TODO - worry about the security implications
  @@nova_config { 'database_url':
    value => "mysql://${user}:${password}@${host}/${name}",
    tag   => $zone,
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
