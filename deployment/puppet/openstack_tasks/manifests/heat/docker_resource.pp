class openstack_tasks::heat::docker_resource (
  $enabled      = true,
  $package_name = 'heat-docker',
) {
  if $enabled {
    package { 'heat-docker':
      ensure  => installed,
      name    => $package_name,
      require => Package['heat-engine'],
    }

    Package['heat-docker'] ~> Service<| title == 'heat-engine' |>
  }
}
