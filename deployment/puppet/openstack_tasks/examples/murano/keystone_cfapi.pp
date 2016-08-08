include ::openstack_tasks::murano::keystone_cfapi
Package<| |> { ensure => 'latest' } ~> Service<| |>
