class neutron {}
class { 'neutron' :}

include ::osnailyfacter::openstack_network::agents::sriov
