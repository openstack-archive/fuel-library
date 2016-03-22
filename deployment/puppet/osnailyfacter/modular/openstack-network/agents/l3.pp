class neutron {}
class { 'neutron' :}

include ::osnailyfacter::openstack_network::agents::l3
