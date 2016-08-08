include ::openstack_tasks::keystone::keystone
Package<| |> { ensure => 'latest' } ~> Service<| |>
