class neutron {}
class { 'neutron' :}

include ::openstack_tasks::openstack_network::agents::metadata
warning('osnailyfacter/modular/./openstack-network/agents/metadata.pp is deprecated in mitaka and will be removed in newton. Please use openstack_tasks/examples/./openstack-network/agents/metadata.pp')
