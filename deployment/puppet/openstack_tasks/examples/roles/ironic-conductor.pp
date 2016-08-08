include ::openstack_tasks::roles::ironic_conductor
Package<| |> { ensure => 'latest' } ~> Service<| |>
