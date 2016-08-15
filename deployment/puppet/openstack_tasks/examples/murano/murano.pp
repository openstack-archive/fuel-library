include ::openstack_tasks::murano::murano
include ::osnailyfacter::upgrade::restart_services

class openstack::firewall {}
include openstack::firewall
