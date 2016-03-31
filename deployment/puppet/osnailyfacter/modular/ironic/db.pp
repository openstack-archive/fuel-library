class { '::openstack_tasks::ironic::db' :}

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
warning('osnailyfacter/modular/./ironic/db.pp is deprecated in mitaka and will be removed in newton. Please use openstack_tasks/examples/./ironic/db.pp')
