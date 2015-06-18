
# uses the keystone packages
# to ensure that we use the latest precise packages
Exec { logoutput => 'on_failure' }

node glance_keystone_mysql {
  class { '::mysql::server': }
  class { '::keystone':
    verbose      => true,
    debug        => true,
    catalog_type => 'sql',
    admin_token  => 'admin_token',
  }
  class { '::keystone::db::mysql':
    password => 'keystone',
  }
  class { '::keystone::roles::admin':
    email    => 'test@puppetlabs.com',
    password => 'ChangeMe',
  }
  class { '::glance::api':
    verbose             => true,
    debug               => true,
    auth_type           => 'keystone',
    keystone_tenant     => 'services',
    keystone_user       => 'glance',
    keystone_password   => 'glance_password',
    database_connection => 'mysql://glance:glance@127.0.0.1/glance',
  }
  class { '::glance::backend::file': }

  class { '::glance::db::mysql':
    password => 'glance',
    dbname   => 'glance',
    user     => 'glance',
    host     => '127.0.0.1',
    # allowed_hosts = undef,
    # $cluster_id = 'localzone'
  }

  class { '::glance::registry':
    verbose             => true,
    debug               => true,
    auth_type           => 'keystone',
    keystone_tenant     => 'services',
    keystone_user       => 'glance',
    keystone_password   => 'glance_password',
    database_connection => 'mysql://glance:glance@127.0.0.1/glance',
  }
  class { '::glance::keystone::auth':
    password => 'glance_pass',
  }
}

node default {
  fail("could not find a matching node entry for ${clientcert}")
}
