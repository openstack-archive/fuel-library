include ::openstack_tasks::roles::cinder
Package<| |> { ensure => 'latest' } ~> Service<| |>
