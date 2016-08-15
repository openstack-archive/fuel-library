include ::openstack_tasks::heat::heat
include ::osnailyfacter::upgrade::restart_services

class mysql::server {}
class mysql::config {}
include mysql::server
include mysql::config
