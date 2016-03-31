class { '::openstack_tasks::murano::murano' :}

class openstack::firewall {}
include openstack::firewall
warning('osnailyfacter/modular/./murano/murano.pp is deprecated in mitaka and will be removed in newton. Please use openstack_tasks/examples/./murano/murano.pp')
