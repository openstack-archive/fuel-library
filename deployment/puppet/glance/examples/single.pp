
node glance {

  class { 'role_glance_sqlite': }

}

node glance_keystone {
  class { 'concat::setup': }
  class { 'keystone::sqlite': }
  class { 'keystone':
    log_verbose  => true,
    log_debug    => true,
    catalog_type => 'sql',
  }->
  class { 'keystone::roles::admin': }
  class { 'role_glance_sqlite': }
  class { 'glance::keystone::auth': }
}

node default {
  fail("could not find a matching node entry for ${clientcert}")
}

class role_glance_sqlite {
  class { 'glance::api':
    log_verbose       => 'True',
    log_debug         => 'True',
    swift_store_user  => 'foo_user',
    swift_store_key   => 'foo_pass',
    auth_type         => 'keystone',
    keystone_tenant   => 'service',
    keystone_user     => 'glance',
    keystone_password => 'glance_password',
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
