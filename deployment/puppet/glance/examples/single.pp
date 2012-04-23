
# uses the keystone packages
# to ensure that we use the latest precise packages
Exec { logoutput => 'on_failure' }

if($::osfamily == 'Debian') {
  stage { 'glance_ppa':
    before => Stage['main'],
  }
  class { 'apt':
    stage => 'glance_ppa',
  }
  class { 'keystone::repo::trunk':
    stage => 'glance_ppa',
  }
}

node glance {

  class { 'role_glance_sqlite': }

}

node glance_keystone {
  class { 'keystone::config::sqlite': }
  class { 'keystone':
    log_verbose  => true,
    log_debug    => true,
    catalog_type => 'sql',
  }->
  class { 'keystone::roles::admin': }
  class { 'role_glance_sqlite': }
  class { 'glance::keystone::auth': }
}

node glance_keystone_mysql {
  class { 'mysql::server': }->
  class { 'keystone':
    log_verbose  => true,
    log_debug    => true,
    catalog_type => 'sql',
  }->
  class { 'keystone::db::mysql':
    password => 'keystone',
  }->
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
    log_verbose       => 'True',
    log_debug         => 'True',
    auth_type         => 'keystone',
    keystone_tenant   => 'service',
    keystone_user     => 'glance',
    keystone_password => 'glance_password',
  }
  class { 'glance::backend::file': }

  class { 'glance::registry':
    log_verbose       => 'True',
    log_debug         => 'True',
    auth_type         => 'keystone',
    keystone_tenant   => 'service',
    keystone_user     => 'glance',
    keystone_password => 'glance_password',
  }

}

class role_glance_mysql {

  class { 'glance::api':
    log_verbose       => 'True',
    log_debug         => 'True',
    auth_type         => 'keystone',
    keystone_tenant   => 'service',
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
    log_verbose       => 'True',
    log_debug         => 'True',
    auth_type         => 'keystone',
    keystone_tenant   => 'service',
    keystone_user     => 'glance',
    keystone_password => 'glance_password',
  }

}
