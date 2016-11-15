class { '::openstack_tasks::ceilometer::compute' :}
class { '::osnailyfacter::upgrade::restart_services' :}
class { '::osnailyfacter::override_resources': }
