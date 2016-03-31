class { '::openstack_tasks::glance::db' :}

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
warning('osnailyfacter/modular/./glance/db.pp is deprecated in mitaka and will be removed in newton. Please use openstack_tasks/examples/./glance/db.pp')
