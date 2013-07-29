# This class nova::manage::floating has been deprecated in favor of nova::manage::floating_range
define nova::manage::floating (
  $network = $name
) {

  File['/etc/nova/nova.conf'] ->
    Exec<| title == 'nova-db-sync' |> ->
      Nova_floating[$name]

  nova_floating { $name:
    ensure        => present,
    network       => $network,
    provider      => 'nova_manage',
  }

}
