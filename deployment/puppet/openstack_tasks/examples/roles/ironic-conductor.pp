class { '::openstack_tasks::roles::ironic_conductor' :}
class { '::osnailyfacter::upgrade::restart_services' :}
class { '::osnailyfacter::override_resources': }
