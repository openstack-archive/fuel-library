include ::openstack_tasks::heat::db

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
Package<| |> { ensure => 'latest' } ~> Service<| |>
