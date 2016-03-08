notice('MODULAR: rsyslog.pp')

class { '::rsyslog':
  relp_package_name   => false,
  gnutls_package_name => false,
  mysql_package_name  => false,
  pgsql_package_name  => false,
}

class { '::openstack::logging':
  role          => 'server',
  proto         => 'both',
  port          => '514',
  show_timezone => true,
}
