class neutron {}
class { 'neutron' :}

class { '::openstack_tasks::openstack_network::plugins::ml2' :}
warning('osnailyfacter/modular/./openstack-network/plugins/ml2.pp is deprecated in mitaka and will be removed in newton. Please use openstack_tasks/examples/./openstack-network/plugins/ml2.pp')
