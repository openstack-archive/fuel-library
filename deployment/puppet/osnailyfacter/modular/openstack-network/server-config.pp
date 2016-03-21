class neutron { }
class { '::neutron' : }

include ::osnailyfacter::openstack_network::server_config
