class { '::openstack_tasks::ceilometer::controller' :}
class { '::osnailyfacter::upgrade::restart_services' :}
class { '::osnailyfacter::override_resources': }
