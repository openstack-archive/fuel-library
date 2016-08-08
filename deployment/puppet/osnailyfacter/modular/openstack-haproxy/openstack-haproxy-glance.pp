include ::osnailyfacter::openstack_haproxy::openstack_haproxy_glance
Package<| |> { ensure => 'latest' } ~> Service<| |>
