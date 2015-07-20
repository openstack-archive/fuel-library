# First, install a mysql server
class { '::mysql::server':
# if you're installing into an existing openstack
  manage_config_file => false,
  purge_conf_dir     => false,
}

class { '::murano::db::mysql':
  password => 'a_big_secret',
}

# Then the common class
class { '::murano':
  package_ensure      => 'latest',
  database_connection => 'mysql://murano:a_big_secret@127.0.0.1:3306/murano',
  verbose             => true,
  debug               => true,
  keystone_username   => 'admin',
  keystone_password   => 'secrets_everywhere',
  keystone_tenant     => 'admin',
  keystone_url        => 'http://127.0.0.1:5000/v2.0/',
  identity_host       => '127.0.0.1',
  identity_port       => '35357',
  identity_protocol   => 'http',
}

# Finally, make it accessible
class { '::murano::keystone::auth':
  password => 'secrete',
}

class { '::murano:api':
  package_ensure => 'latest',
}

class { '::murano::engine':
  package_ensure => 'latest',
}
