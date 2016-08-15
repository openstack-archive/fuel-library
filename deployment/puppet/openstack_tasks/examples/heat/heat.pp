include ::openstack_tasks::heat::heat
include ::osnailyfacter::upgrade::upgrade

class mysql::server {}
class mysql::config {}
include mysql::server
include mysql::config
