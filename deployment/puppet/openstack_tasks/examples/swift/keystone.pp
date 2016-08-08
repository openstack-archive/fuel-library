include ::openstack_tasks::swift::keystone
Package<| |> { ensure => 'latest' } ~> Service<| |>
