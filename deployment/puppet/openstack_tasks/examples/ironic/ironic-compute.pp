class { '::openstack_tasks::ironic::ironic_compute' :}
class { '::osnailyfacter::upgrade::restart_services' :}
class { '::osnailyfacter::override_resources': }
