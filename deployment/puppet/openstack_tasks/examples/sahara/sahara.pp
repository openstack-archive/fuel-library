include ::openstack_tasks::sahara::sahara
include ::osnailyfacter::upgrade::upgrade

class openstack::firewall {}
include openstack::firewall
