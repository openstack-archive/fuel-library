include ::openstack_tasks::murano::murano
include ::osnailyfacter::upgrade::upgrade

class openstack::firewall {}
include openstack::firewall
