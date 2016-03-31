class { '::openstack_tasks::murano::cfapi' :}

class openstack::firewall {}
include openstack::firewall
warning('osnailyfacter/modular/./murano/cfapi.pp is deprecated in mitaka and will be removed in newton. Please use openstack_tasks/examples/./murano/cfapi.pp')
