class cs_resource_test(
  $ensure = 'present'
) {
  cs_resource { 'cs_resource_simple':
    ensure             => $ensure,
    primitive_class    => 'ocf',
    primitive_provider => 'pacemaker',
    primitive_type     => 'Dummy',
    operations         => { # hash-like operations syntax
      'monitor' => {
        'interval' => '20'
      }
    },
    metadata => {
      'fake' => '1',
      'target-role' => 'started', # ignored in insync?, auto-upcase
    }
  }

  cs_resource { 'cs_resource_clone':
    ensure             => $ensure,
    primitive_class    => 'ocf',
    primitive_provider => 'pacemaker',
    primitive_type     => 'Dummy',
    operations         => [ # array-like operations syntax
    {
      'name'     => 'monitor',
      'interval' => '20',
    },
    {
      'name'     => 'start',
      'interval' => '0',
      'timeout'  => '20'
    }
    ],
    parameters => {
      'fake' => '1',
    },
    metadata => {
      'migration-threshold' => '3',
    },
    complex_type     => 'clone',
    complex_metadata => {
      'interleave' => 'true',
      'is-managed' => 'true', # ignored in insync?
    }
  }

  cs_resource { 'cs_resource_master':
    ensure             => $ensure,
    primitive_class    => 'ocf',
    primitive_provider => 'pacemaker',
    primitive_type     => 'Stateful',
    operations         => [
    {
      'name' => 'monitor',
      'interval' => '20',
    },
    {
      'name' => 'monitor',
      'interval' => '10',
      'role' => 'master', # master-only operation, auto-upcase
    },
    {
      'name' => 'start',
      'timeout'  => '30',
    },
    {
      'name' => 'stop',
      'timeout'  => '30',
    },
    {
      'name' => 'promote',
      'timeout'  => '30',
    }
    ],
    parameters => {
      'fake' => '1',
    },
    metadata => {
      'migration-threshold' => '3',
    },
    complex_type     => 'master',
    complex_metadata => {
      'master-max' => '1',
    }
  }
}
