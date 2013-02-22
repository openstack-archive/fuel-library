#Define shadow CIB

Cs_resource {cib => 'shadow'}
Cs_property {cib => 'shadow'}
Cs_order {cib => 'shadow'}
Cs_colocation {cib => 'shadow'}
Cs_group {cib => 'shadow'}

Class['corosync']->Cs_shadow['shadow']->Cs_property['expected-quorum-votes']->
Cs_property['no-quorum-policy']->Cs_property['stonith-enabled']->Cs_property['placement-strategy']->
Cs_resource['bar']->Cs_resource['blort']->Cs_resource['foo']->Cs_colocation['foo-with-bar']->
Cs_colocation['bar-with-blort']->Cs_order['foo-before-bar']

corosync::service { 'pacemaker':
  version => '0',
  notify  => Service['corosync'],
}
class { 'corosync':
  enable_secauth    => 'off',
  bind_address      => '192.168.122.0',
  multicast_address => '239.1.1.2',
}
cs_shadow {'shadow': cib=>'shadow'}
cs_property { 'expected-quorum-votes':
  ensure => present,
  cib => 'shadow',
  value  => '2',
}
cs_property { 'no-quorum-policy':
  ensure => present,
  cib => 'shadow',
  value  => 'ignore',
}
cs_property { 'stonith-enabled':
  cib => 'shadow',
  ensure => present,
  value  => false,
}
cs_property { 'placement-strategy':
  cib => 'shadow',
  ensure => absent,
  value  => 'default',
}
cs_resource { 'bar':
  ensure          => present,
  primitive_class => 'ocf',
  provided_by     => 'pacemaker',
  primitive_type  => 'Dummy',
  multistate_hash  => { type => 'master' },
  operations      => {
    'monitor'  => {
      'interval' => '20'
    }
  },
}
cs_resource { 'blort':
  ensure          => present,
  primitive_class => 'ocf',
  provided_by     => 'pacemaker',
  primitive_type  => 'Dummy',
  multistate_hash => { 'type' => 'clone', 'name' => 'blort_clone' },
  operations      => {
    'monitor' => {
      'interval' => '20'
    },
    'start'   => {
      'interval' => '0',
      'timeout'  => '20'
    }
  }
}
cs_resource { 'foo':
  ensure          => present,
  primitive_class => 'ocf',
  provided_by     => 'pacemaker',
  multistate_hash => { 'type' => 'clone', 'name' => 'super_good_foo_clone' },
  primitive_type  => 'Dummy',
}
cs_colocation { 'foo-with-bar':
  ensure     => present,
  primitives => [ 'foo', 'bar' ],
  score      => 'INFINITY',
}
cs_colocation { 'bar-with-blort':
  ensure     => present,
  primitives => [ 'foo', 'blort' ],
  score      => 'INFINITY',
}
cs_order { 'foo-before-bar':
  ensure => present,
  first  => 'foo',
  second => 'bar',
  score  => 'INFINITY',
}
