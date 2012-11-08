class mysql::server::account_security {
  # Some installations have some default users which are not required.
  # We remove them here. You can subclass this class to overwrite this behavior.
  if $::fqdn {
     database_user { [ "root@${::fqdn}", "@${::fqdn}" ]:
    ensure  => 'absent',
    require => Class['mysql::config'],
  }

  }
  
  database_user { [ 'root@127.0.0.1', "root@${::hostname}", "@${::hostname}", '@localhost', '@%' ]:
    ensure  => 'absent',
    require => Class['mysql::config'],
  }
  database { 'test':
    ensure  => 'absent',
    require => Class['mysql::config'],
  }
}
