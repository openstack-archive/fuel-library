cs_property { 'expected-quorum-votes':
  ensure => present,
  value  => '2',
} ->
cs_property { 'no-quorum-policy':
  ensure => present,
  value  => 'ignore',
} ->
cs_property { 'stonith-enabled':
  ensure => present,
  value  => false,
} ->
cs_property { 'placement-strategy':
  ensure => absent,
  value  => 'default',
} ->
cs_resource { 'bar':
  ensure          => present,
  primitive_class => 'ocf',
  provided_by     => 'pacemaker',
  primitive_type  => 'Dummy',
  operations      => {
    'monitor'  => {
      'interval' => '20'
    }
  },
} ->
cs_resource { 'blort':
  ensure          => present,
  primitive_class => 'ocf',
  provided_by     => 'pacemaker',
  primitive_type  => 'Dummy',
  multistate_hash => { type => 'master' },
  operations      => {
    'monitor' => {
      'interval' => '20'
    },
    'start'   => {
      'interval' => '0',
      'timeout'  => '20'
    }
  },
} ->
cs_resource { 'foo':
  ensure          => present,
  primitive_class => 'ocf',
  provided_by     => 'pacemaker',
  primitive_type  => 'Dummy',
} ->
cs_colocation { 'foo-with-bar':
  ensure     => present,
  primitives => [ 'foo', 'bar' ],
  score      => 'INFINITY',
} ->
cs_colocation { 'bar-with-blort':
  ensure     => present,
  primitives => [ 'bar', 'ms_blort' ],
  score      => 'INFINITY',
} ->
cs_order { 'foo-before-bar':
  ensure => present,
  first  => 'foo',
  second => 'bar',
  score  => 'INFINITY',
}
