class cs_order_test (
  $ensure = 'present'
) {
  $resource1 = 'order_test_primitive1'
  $resource2 = 'order_test_primitive2'
  $order = 'order_test'
  
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
  
  cs_order { $order :
    ensure => $ensure,
    first  => $resource1,
    second => $resource2,
    score  => '100',
  }
  
  if $ensure == 'present' {
    Cs_resource[$resource1] -> Cs_order[$order]
    Cs_resource[$resource2] -> Cs_order[$order]
  } else {
    Cs_order[$order] -> Cs_resource[$resource1]
    Cs_order[$order] -> Cs_resource[$resource2]
  }

}
