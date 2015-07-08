# Creates floating networks
#
# === Parameters:
#
# [*network*]
#  (mandatory) The network name to work on
#
define nova::manage::floating ( $network ) {

  File['/etc/nova/nova.conf'] -> Nova_floating[$name]
  Exec<| title == 'nova-db-sync' |> -> Nova_floating[$name]

  nova_floating { $name:
    ensure   => present,
    network  => $network,
    provider => 'nova_manage',
  }

}
