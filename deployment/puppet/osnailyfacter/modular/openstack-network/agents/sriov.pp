class neutron {}
class { 'neutron' :}

class { '::openstack_tasks::openstack_network::agents::sriov' :}
warning('osnailyfacter/modular/./openstack-network/agents/sriov.pp is deprecated in mitaka and will be removed in newton. Please use openstack_tasks/examples/./openstack-network/agents/sriov.pp')
