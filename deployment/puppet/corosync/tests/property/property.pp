class cs_property_test(
  $ensure = 'present'
) {

  cs_property { 'expected-quorum-votes':
    ensure => $ensure,
    value  => '2',
  }
  
  cs_property { 'no-quorum-policy':
    ensure => $ensure,
    value  => 'ignore',
  }
  
  cs_property { 'stonith-enabled':
    ensure => $ensure,
    value  => false,
  }
  
  cs_property { 'placement-strategy':
    ensure => $ensure,
    value  => 'default',
  }

}