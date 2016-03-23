include ::osnailyfacter::openstack_network::db

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
