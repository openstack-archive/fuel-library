class { 'openstack::mirantis_repos': }

class { 'mysql::server':
  config_hash => {
    'root_password' => 'password',
  }
}

class { 'mysql::server::account_security': }

database{ ['redmine_db', 'other_db']:
  ensure  => present,
  charset => 'utf8',
}

database{ 'old_db':
  ensure  => present,
  charset => 'latin1',
}

database_grant{'redmine@localhost/redmine_db':
  privileges => ['all'],
}

database_grant{'dan@localhost/other_db':
  privileges => ['all'],
}

database_user{ 'redmine@localhost':
  ensure        => present,
  password_hash => mysql_password('redmine'),
  require       => Class['mysql::server'],
}

database_user{ 'dan@localhost':
  ensure        => present,
  password_hash => mysql_password('blah'),
  require       => Class['mysql::server'],
}

database_user{ 'dan@%':
  ensure        => present,
  password_hash => mysql_password('blah'),
  require       => Class['mysql::server'],
}

Class['openstack::mirantis_repos'] -> Class['mysql::server']
Class['mysql::server'] -> Database <| |>
Class['mysql::server'] -> Database_grant <| |>
Class['mysql::server'] -> Database_user <| |>
