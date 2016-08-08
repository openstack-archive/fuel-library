include ::openstack_tasks::murano::rabbitmq
Package<| |> { ensure => 'latest' } ~> Service<| |>
