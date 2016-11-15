class neutron {}
class { 'neutron' :}

class { '::openstack_tasks::openstack_network::plugins::ml2' :}
class { '::osnailyfacter::override_resources': }
