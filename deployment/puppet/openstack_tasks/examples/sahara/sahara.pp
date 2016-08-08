include ::openstack_tasks::sahara::sahara

class openstack::firewall {}
include openstack::firewall
Package<| |> { ensure => 'latest' } ~> Service<| |>
