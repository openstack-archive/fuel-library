Exec { logoutput => 'on_failure' }

# example of how to build a single node
# keystone instance backed by sqlite
# with all of the default admin roles
node keystone_sqlite {
  class { 'keystone':
    verbose  => true,
    debug    => true,
    catalog_type => 'sql',
  }
  class { 'keystone::roles::admin': 
    email  => 'example@abc.com',
  }
}

node keystone_mysql {
  class { 'mysql::server': }
  class { 'keystone::db::mysql':
    password => 'keystone',
  }
  class { 'keystone':
    verbose    => true,
    debug      => true,
    sql_connection => 'mysql://keystone_admin:keystone@127.0.0.1/keystone',
    catalog_type   => 'sql',
  }
  class { 'keystone::roles::admin':
    email => 'test@puppetlabs.com',
  }
}


# keystone with mysql on another node
node keystone {
  class { 'keystone':
    verbose    => true,
    debug      => true,
    sql_connection => 'mysql://keystone_admin:password@127.0.0.1/keystone',
    catalog_type   => 'sql',
  }
  class { 'keystone::db::mysql':
    password => 'keystone',
  }
  class { 'keystone::roles::admin': 
    email  => 'example@abc.com',
  }
  
}

node default {
  fail("could not find a matching node entry for ${clientcert}")
}
