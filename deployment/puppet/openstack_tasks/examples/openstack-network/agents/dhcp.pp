class neutron {}
class { 'neutron' :}

include ::openstack_tasks::openstack_network::agents::dhcp
include ::osnailyfacter::upgrade::upgrade
