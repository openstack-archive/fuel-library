include ::openstack_tasks::keystone::workloads_collector_add
Package<| |> { ensure => 'latest' } ~> Service<| |>
