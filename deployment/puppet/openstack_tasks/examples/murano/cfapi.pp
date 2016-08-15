include ::openstack_tasks::murano::cfapi
include ::osnailyfacter::upgrade::restart_services

class openstack::firewall {}
include openstack::firewall
