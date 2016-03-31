class { '::openstack_tasks::murano::murano' :}

class openstack::firewall {}
include openstack::firewall
