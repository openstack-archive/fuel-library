class cs_colocation_test (
  $ensure = 'present'
) {
  $resource1 = 'colocation_test_primitive1'
  $resource2 = 'colocation_test_primitive2'
  $colocation = 'colocation_test'

  cs_resource { $resource1 :
    ensure => $ensure,
    primitive_class    => 'ocf',
    primitive_provider => 'pacemaker',
    primitive_type     => 'Dummy',
  }

  cs_resource { $resource2 :
    ensure => $ensure,
    primitive_class    => 'ocf',
    primitive_provider => 'pacemaker',
    primitive_type     => 'Dummy',
  }

  cs_colocation { $colocation :
    ensure => $ensure,
    primitives => [ $resource1, $resource2 ],
    score => '100',
  }

  if $ensure == 'present' {
    Cs_resource[$resource1] -> Cs_colocation[$colocation]
    Cs_resource[$resource2] -> Cs_colocation[$colocation]
  } else {
    Cs_colocation[$colocation] -> Cs_resource[$resource1]
    Cs_colocation[$colocation] -> Cs_resource[$resource2]
  }

}
