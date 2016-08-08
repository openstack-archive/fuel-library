include ::openstack_tasks::ironic::ironic_compute
Package<| |> { ensure => 'latest' } ~> Service<| |>
