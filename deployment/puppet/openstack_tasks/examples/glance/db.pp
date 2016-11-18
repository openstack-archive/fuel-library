include ::openstack_tasks::glance::db

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
include ::osnailyfacter::override_resources
