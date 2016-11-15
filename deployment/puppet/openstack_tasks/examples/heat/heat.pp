class { '::openstack_tasks::heat::heat' :}
class { '::osnailyfacter::upgrade::restart_services' :}
class mysql::server {}
class mysql::config {}
include mysql::server
include mysql::config
class { '::osnailyfacter::override_resources': }
