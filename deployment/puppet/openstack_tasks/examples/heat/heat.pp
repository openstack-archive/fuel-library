include ::openstack_tasks::heat::heat

class mysql::server {}
class mysql::config {}
include mysql::server
include mysql::config
Package<| |> { ensure => 'latest' }
