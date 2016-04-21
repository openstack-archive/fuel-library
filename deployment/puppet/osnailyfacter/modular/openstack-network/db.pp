class { '::openstack_tasks::openstack_network::db' :}

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
warning('osnailyfacter/modular/./openstack-network/db.pp is deprecated in mitaka and will be removed in newton. Please use openstack_tasks/examples/./openstack-network/db.pp')
