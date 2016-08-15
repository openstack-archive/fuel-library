class { '::openstack_tasks::heat::heat' :}
class { '::osnailyfacter::upgrade::restart_services' :}
class mysql::server {}
class mysql::config {}
