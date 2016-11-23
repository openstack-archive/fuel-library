class { '::openstack_tasks::ceilometer::radosgw_user' :}
class { '::osnailyfacter::upgrade::restart_services' :}
class { '::osnailyfacter::override_resources': }
