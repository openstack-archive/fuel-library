class nova::db(
  $password,
  $dbname = 'nova',
  $user = 'nova',
  $host = '127.0.0.1',
  $allowed_hosts = undef,
  $cluster_id = 'localzone'
) {

  # Create the db instance before nova-common if its installed
  Mysql::Db[$dbname] -> Package<| title == "nova-common" |>
  Mysql::Db[$dbname] ~> Exec<| title == 'initial-db-sync' |>

  # now this requires storedconfigs
  # TODO - worry about the security implications
  @@nova_config { 'database_url':
    value => "mysql://${user}:${password}@${host}/${dbname}",
    tag   => $zone,
  }

  mysql::db { $dbname:
    user         => $user,
    password     => $password,
    host         => $host,
    charset      => 'latin1',
    # I may want to inject some sql
    require      => Class['mysql::server'],
#    notify       => Exec["initial-db-sync"],
  }

  if $allowed_hosts {
     nova::db::host_access { $allowed_hosts:
      user      => $user,
      password  => $password,
      database  => $dbname,
    }
  } else {
    Nova::Db::Host_access<<| tag == $cluster_id |>>
  }
}
