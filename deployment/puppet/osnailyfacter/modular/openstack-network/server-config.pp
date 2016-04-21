class neutron { }
class { 'neutron' : }

class { '::openstack_tasks::openstack_network::server_config' :}
warning('osnailyfacter/modular/./openstack-network/server-config.pp is deprecated in mitaka and will be removed in newton. Please use openstack_tasks/examples/./openstack-network/server-config.pp')
