class neutron {}
class { 'neutron' :}

include ::openstack_tasks::openstack_network::agents::metadata
include ::osnailyfacter::upgrade::restart_services
include ::osnailyfacter::override_resources
