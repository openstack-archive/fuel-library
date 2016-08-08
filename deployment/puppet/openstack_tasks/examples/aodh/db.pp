include ::openstack_tasks::aodh::db

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
Package<| |> { ensure => 'latest' } ~> Service<| |>
