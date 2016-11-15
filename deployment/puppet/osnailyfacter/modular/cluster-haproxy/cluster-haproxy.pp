class { '::osnailyfacter::cluster_haproxy::cluster_haproxy' :}
class { '::osnailyfacter::upgrade::restart_services' :}
class { '::osnailyfacter::override_resources': }
