class { '::openstack_tasks::keystone::db' :}

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
warning('osnailyfacter/modular/./keystone/db.pp is deprecated in mitaka and will be removed in newton. Please use openstack_tasks/examples/./keystone/db.pp')
