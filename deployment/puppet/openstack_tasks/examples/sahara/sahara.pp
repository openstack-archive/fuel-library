class { '::openstack_tasks::sahara::sahara' :}
class { '::osnailyfacter::upgrade::restart_services' :}
class openstack::firewall {}
include openstack::firewall
class { '::osnailyfacter::override_resources': }
