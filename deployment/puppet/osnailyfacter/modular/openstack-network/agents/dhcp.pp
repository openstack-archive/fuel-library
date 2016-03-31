class neutron {}
class { 'neutron' :}

class { '::openstack_tasks::openstack_network::agents::dhcp' :}
warning('osnailyfacter/modular/./openstack-network/agents/dhcp.pp is deprecated in mitaka and will be removed in newton. Please use openstack_tasks/examples/./openstack-network/agents/dhcp.pp')
