include ::openstack_tasks::murano::cfapi

class openstack::firewall {}
include openstack::firewall
Package<| |> { ensure => 'latest' } ~> Service<| |>
