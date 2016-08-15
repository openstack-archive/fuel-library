include ::openstack_tasks::murano::cfapi
include ::osnailyfacter::upgrade

class openstack::firewall {}
include openstack::firewall
