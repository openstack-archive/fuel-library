class { '::openstack_tasks::murano::upload_murano_package' :}
Package<| |> { ensure => 'latest' }
