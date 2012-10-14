# this is a hack that I have to do b/c openstack nova
# sets up a route to reroute calls to the metadata server
# to its own server which fails

Exec { logoutput => 'on_failure' }

# example of how to build a single node
# keystone instance backed by sqlite
# with all of the default admin roles
node keystone {
  class { 'keystone::config::sqlite': }
  class { 'keystone':
    log_verbose  => true,
    log_debug    => true,
    catalog_type => 'sql',
  }
  class { 'keystone::roles::admin': }
    email  => 'example@abc.com',
}

node keystone_mysql {
  class { 'mysql::server': }
  class { 'keystone::config::mysql':
    password => 'keystone'
  }
  class { 'keystone':
    log_verbose  => true,
    log_debug    => true,
    catalog_type => 'sql',
  }
  class { 'keystone::db::mysql':
    password => 'keystone',
  }
  class { 'keystone::roles::admin': }
    email  => 'example@abc.com',
}

node default {
  fail("could not find a matching node entry for ${clientcert}")
}
