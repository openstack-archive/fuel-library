class neutron { }
class { 'neutron' : }

class { '::openstack_tasks::openstack_network::server_config' :}
class { '::osnailyfacter::override_resources': }
