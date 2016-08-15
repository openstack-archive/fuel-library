include ::openstack_tasks::murano::murano
include ::osnailyfacter::upgrade

class openstack::firewall {}
include openstack::firewall
