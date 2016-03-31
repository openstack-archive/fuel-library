class { '::openstack_tasks::heat::heat' :}

class mysql::server {}
class mysql::config {}
include mysql::server
include mysql::config
warning('osnailyfacter/modular/./heat/heat.pp is deprecated in mitaka and will be removed in newton. Please use openstack_tasks/examples/./heat/heat.pp')
