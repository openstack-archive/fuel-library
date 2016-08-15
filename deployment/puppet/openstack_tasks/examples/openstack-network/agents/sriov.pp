class neutron {}
class { 'neutron' :}

include ::openstack_tasks::openstack_network::agents::sriov
include ::osnailyfacter::upgrade::restart_services
