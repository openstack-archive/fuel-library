class neutron {}
class { 'neutron' :}
class { '::openstack_tasks::openstack_network::agents::l3' :}
class { '::osnailyfacter::upgrade::restart_services' :}
