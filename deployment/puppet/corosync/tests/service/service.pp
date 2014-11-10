class cs_service_test (
  $resource_ensure = 'present',
  $service_ensure = 'running',
  $enable = true
) {
  $resource1 = 'simple_service_test_primitive'
  $resource2 = 'clone_service_test_primitive'

  cs_resource { $resource1 :
    ensure => $resource_ensure,
    primitive_class    => 'ocf',
    primitive_provider => 'pacemaker',
    primitive_type     => 'Dummy',
  }

  cs_resource { $resource2 :
    ensure => $resource_ensure,
    primitive_class    => 'ocf',
    primitive_provider => 'pacemaker',
    primitive_type     => 'Dummy',
    complex_type       => 'clone',
  }

  Service {
    ensure   => $service_ensure,
    enable   => $enable,
    provider => 'pacemaker',
  }

  service { $resource1 :}
  service { $resource2 :}

  Cs_resource<||> -> Service<||>

}
