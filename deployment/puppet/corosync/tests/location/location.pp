class cs_location_test (
  $node_name = 'my_node',
  $ensure = 'present'
) {
  $resource = 'location_test_primitive'
  $location1 = 'score_location_test'
  $location2 = 'rule_location_test'

  cs_resource { $resource :
    ensure => $ensure,
    primitive_class    => 'ocf',
    primitive_provider => 'pacemaker',
    primitive_type     => 'Dummy',
  }

  cs_location { $location1 :
    ensure => $ensure,
    primitive => $resource,
    node_score => '100',
    node_name => $node_name,
  }

  cs_location { $location2 :
    ensure => $ensure,
    primitive => $resource,
    rules     => {
      'score'   => '100',
      'expressions' => [
        {
          'attribute' => '#uname',
          'operation' => 'eq',
          'value' => $node_name,
        },
      ],
    },
  }

  if $ensure == 'present' {
    Cs_resource[$resource] -> Cs_location[$location1]
    Cs_resource[$resource] -> Cs_location[$location2]
  } else {
    Cs_location[$location1] -> Cs_resource[$resource]
    Cs_location[$location2] -> Cs_resource[$resource]
  }

}