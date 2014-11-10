class cs_rsc_default_test (
  $ensure = 'present'
) {

  cs_rsc_default { 'resource-stickiness':
    ensure => $ensure,
    value  => '100',
  }

  cs_rsc_default { 'migration-threshold':
    ensure => $ensure,
    value  => '3',
  }

}
