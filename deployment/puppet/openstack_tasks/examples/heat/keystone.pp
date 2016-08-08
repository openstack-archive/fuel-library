include ::openstack_tasks::heat::keystone
Package<| |> { ensure => 'latest' } ~> Service<| |>
