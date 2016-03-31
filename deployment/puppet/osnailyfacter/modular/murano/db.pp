class { '::openstack_tasks::murano::db' :}

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
class murano::api {}
include murano::api
warning('osnailyfacter/modular/./murano/db.pp is deprecated in mitaka and will be removed in newton. Please use openstack_tasks/examples/./murano/db.pp')
