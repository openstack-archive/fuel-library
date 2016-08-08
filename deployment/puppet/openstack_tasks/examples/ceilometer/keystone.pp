include ::openstack_tasks::ceilometer::keystone
Package<| |> { ensure => 'latest' } ~> Service<| |>
