class neutron {}
class { 'neutron' :}

include ::openstack_tasks::openstack_network::agents::dhcp
include ::osnailyfacter::upgrade::restart_services
include ::osnailyfacter::override_resources
