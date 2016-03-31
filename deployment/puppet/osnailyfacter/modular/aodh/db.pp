class { '::openstack_tasks::aodh::db' :}

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
warning('osnailyfacter/modular/./aodh/db.pp is deprecated in mitaka and will be removed in newton. Please use openstack_tasks/examples/./aodh/db.pp')
