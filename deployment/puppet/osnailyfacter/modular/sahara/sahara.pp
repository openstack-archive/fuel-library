class { '::openstack_tasks::sahara::sahara' :}

class openstack::firewall {}
include openstack::firewall
warning('osnailyfacter/modular/./sahara/sahara.pp is deprecated in mitaka and will be removed in newton. Please use openstack_tasks/examples/./sahara/sahara.pp')
