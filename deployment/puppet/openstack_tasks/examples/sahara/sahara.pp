include ::openstack_tasks::sahara::sahara
include ::osnailyfacter::upgrade::restart_services

class openstack::firewall {}
include openstack::firewall
