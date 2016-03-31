class neutron {}
class { 'neutron' :}

class { '::openstack_tasks::openstack_network::agents::l3' :}
warning('osnailyfacter/modular/./openstack-network/agents/l3.pp is deprecated in mitaka and will be removed in newton. Please use openstack_tasks/examples/./openstack-network/agents/l3.pp')
