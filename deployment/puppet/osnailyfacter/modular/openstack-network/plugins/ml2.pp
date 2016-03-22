class neutron {}
class { 'neutron' :}

include ::osnailyfacter::openstack_network::plugins::ml2
