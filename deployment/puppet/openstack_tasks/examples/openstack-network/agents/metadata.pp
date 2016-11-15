class neutron {}
class { 'neutron' :}
class { '::openstack_tasks::openstack_network::agents::metadata' :}
class { '::osnailyfacter::upgrade::restart_services' :}
class { '::osnailyfacter::override_resources': }
