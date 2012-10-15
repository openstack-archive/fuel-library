
# uses the keystone packages
# to ensure that we use the latest precise packages
Exec { logoutput => 'on_failure' }

node glance {

  class { 'role_glance_sqlite': }

}

node glance_keystone {
  class { 'keystone::config::sqlite': }
  class { 'keystone':
    verbose  => true,
    debug    => true,
    catalog_type => 'sql',
  }
  class { 'keystone::roles::admin': }
  class { 'role_glance_sqlite': }
  class { 'glance::keystone::auth': }
}

node glance_keystone_mysql {
  class { 'mysql::server': }
  class { 'keystone':
    verbose  => true,
    debug    => true,
    catalog_type => 'sql',
  }
  class { 'keystone::db::mysql':
    password => 'keystone',
  }
  class { 'keystone::roles::admin': }
  class { 'role_glance_mysql': }
  class { 'glance::keystone::auth': }
  class { 'keystone::config::mysql':
    password => 'keystone'
  }
}

node default {
  fail("could not find a matching node entry for ${clientcert}")
}

class role_glance_sqlite {

  class { 'glance::api':
    verbose       => 'True',
    debug         => 'True',
    auth_type         => 'keystone',
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => 'glance_password',
  }
  class { 'glance::backend::file': }

  class { 'glance::registry':
    verbose       => 'True',
    debug         => 'True',
    auth_type         => 'keystone',
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => 'glance_password',
  }

}

class role_glance_mysql {

  class { 'glance::api':
    verbose       => 'True',
    debug         => 'True',
    auth_type         => 'keystone',
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => 'glance_password',
  }
  class { 'glance::backend::file': }

  class { 'glance::db::mysql':
    password => 'glance',
    dbname   => 'glance',
    user     => 'glance',
    host     => '127.0.0.1',
   # allowed_hosts = undef,
   # $cluster_id = 'localzone'
  }

  class { 'glance::registry':
    verbose       => 'True',
    debug         => 'True',
    auth_type         => 'keystone',
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => 'glance_password',
    sql_connection    => 'mysql://glance:glance@127.0.0.1/glance',
  }

}
