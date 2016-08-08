include ::openstack_tasks::murano::murano

class openstack::firewall {}
include openstack::firewall
Package<| |> { ensure => 'latest' } ~> Service<| |>
