class { '::openstack_tasks::sahara::db' :}

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
class sahara::api {}
include sahara::api
class { '::osnailyfacter::override_resources': }
