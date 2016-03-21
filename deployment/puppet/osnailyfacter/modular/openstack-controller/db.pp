include ::osnailyfacter::openstack_controller::db

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
