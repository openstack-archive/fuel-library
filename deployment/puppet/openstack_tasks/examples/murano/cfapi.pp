class { '::openstack_tasks::murano::cfapi' :}
class { '::osnailyfacter::upgrade::restart_services' :}
class openstack::firewall {}
include openstack::firewall
class { '::osnailyfacter::override_resources': }
