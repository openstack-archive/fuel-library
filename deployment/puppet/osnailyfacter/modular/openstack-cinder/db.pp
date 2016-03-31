class { '::openstack_tasks::openstack_cinder::db' :}

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
warning('osnailyfacter/modular/./openstack-cinder/db.pp is deprecated in mitaka and will be removed in newton. Please use openstack_tasks/examples/./openstack-cinder/db.pp')
