include ::openstack_tasks::murano::cfapi
include ::osnailyfacter::upgrade::upgrade

class openstack::firewall {}
include openstack::firewall
