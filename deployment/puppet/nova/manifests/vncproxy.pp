class nova::vncproxy(
) {

  Package['nova-vncproxy'] -> Exec<| title == 'initial-db-sync' |>

  package { 'nova-vncproxy':
    ensure => present,
  }

}
