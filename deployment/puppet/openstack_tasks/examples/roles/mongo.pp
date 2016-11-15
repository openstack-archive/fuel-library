class { '::openstack_tasks::roles::mongo' :}
class { '::osnailyfacter::upgrade::restart_services' :}
class { '::osnailyfacter::override_resources': }
