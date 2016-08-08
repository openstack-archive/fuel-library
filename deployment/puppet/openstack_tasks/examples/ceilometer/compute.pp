include ::openstack_tasks::ceilometer::compute
Package<| |> { ensure => 'latest' } ~> Service<| |>
