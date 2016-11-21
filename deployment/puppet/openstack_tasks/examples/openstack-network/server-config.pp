class neutron { }
class { 'neutron' : }

include ::openstack_tasks::openstack_network::server_config
include ::osnailyfacter::override_resources
