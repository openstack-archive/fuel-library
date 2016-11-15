class { '::openstack_tasks::murano::db' :}

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
class murano::api {}
include murano::api
class { '::osnailyfacter::override_resources': }
