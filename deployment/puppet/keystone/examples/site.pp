# this is a hack that I have to do b/c openstack nova
# sets up a route to reroute calls to the metadata server
# to its own server which fails

Exec { logoutput => 'on_failure' }

if($::osfamily == 'Debian') {
  stage { 'keystone_ppa':
    before => Stage['main'],
  }

  class { 'apt':
    stage => 'keystone_ppa',
  }
  class { 'keystone::repo::trunk':
    stage => 'keystone_ppa',
  }
}

# example of how to build a single node
# keystone instance backed by sqlite
# with all of the default admin roles
node keystone {
  class { 'keystone::config::sqlite': }
  class { 'keystone':
    log_verbose  => true,
    log_debug    => true,
    catalog_type => 'sql',
  }->
  class { 'keystone::roles::admin': }
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
  }->
  class { 'keystone::mysql':
    password => 'keystone',
  }->
  class { 'keystone::roles::admin': }
}

node default {
  fail("could not find a matching node entry for ${clientcert}")
}
