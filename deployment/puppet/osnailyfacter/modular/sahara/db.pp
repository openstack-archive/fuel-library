class { '::openstack_tasks::sahara::db' :}

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
class sahara::api {}
include sahara::api
warning('osnailyfacter/modular/./sahara/db.pp is deprecated in mitaka and will be removed in newton. Please use openstack_tasks/examples/./sahara/db.pp')
