class neutron {}
class { 'neutron' :}

include ::openstack_tasks::openstack_network::plugins::ml2
