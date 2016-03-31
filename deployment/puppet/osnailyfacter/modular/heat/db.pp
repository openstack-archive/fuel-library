class { '::openstack_tasks::heat::db' :}

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
warning('osnailyfacter/modular/./heat/db.pp is deprecated in mitaka and will be removed in newton. Please use openstack_tasks/examples/./heat/db.pp')
