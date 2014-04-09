#
# This class implements basic nova services.
# It is introduced to attempt to consolidate
# common code.
#
# It also allows users to specify ad-hoc services
# as needed
#
#
# This define creates a service resource with title nova-${name} and
# conditionally creates a package resource with title nova-${name}
#
define nova::generic_service(
  $package_name,
  $service_name,
  $enabled        = false,
  $ensure_package = 'present'
) {

  include nova::params

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  $nova_title = "nova-${name}"
  # ensure that the service is only started after
  # all nova config entries have been set
  Exec['post-nova_config'] ~> Service<| title == $nova_title |>
  # ensure that the service has only been started
  # after the initial db sync
  Exec<| title == 'nova-db-sync' |> ~> Service<| title == $nova_title |>


  # I need to mark that ths package should be
  # installed before nova_config
  if ($package_name) {
    package { $nova_title:
      ensure => $ensure_package,
      name   => $package_name,
      notify => Service[$nova_title],
    }
  }

  if ($service_name) {
    service { $nova_title:
      ensure    => $service_ensure,
      name      => $service_name,
      enable    => $enabled,
      hasstatus => true,
      require   => [Package['nova-common'], Package[$nova_title]],
    }
  }

}
