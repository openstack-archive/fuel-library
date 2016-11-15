class { '::openstack_tasks::keystone::db' :}

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
class { '::osnailyfacter::override_resources': }
