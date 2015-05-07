#
class openstack::logrotate (
  $role     = 'client',
  $rotation = 'weekly',
  $keep     = '4',
  $minsize  = '30M',
  $maxsize  = '100M',
  $debug    = false,
) {
  validate_re($rotation, 'daily|weekly|monthly')
  $logrotatefile = '/etc/logrotate.d/fuel.nodaily'

  if $role == 'server' {
    # Configure log rotation for master node and docker containers
    file { $logrotatefile:
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('openstack/10-fuel-docker.conf.erb'),
    }
  } else {
    # Configure log rotation for other nodes
    file { $logrotatefile:
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('openstack/10-fuel.conf.erb'),
    }
  }

  # Configure (ana)cron for fuel custom hourly logrotations
  class { '::anacron':
    debug => $debug,
  }

  # Our custom cronjob overlaps with daily schedule, so we need to address it
  exec { 'logrotate-tabooext':
    command => 'sed -i "/^include/i tabooext + .nodaily" /etc/logrotate.conf',
    path    => [ '/bin', '/usr/bin' ],
    onlyif  => 'test -f /etc/logrotate.conf',
    unless  => 'grep -q tabooext /etc/logrotate.conf',
  }

  case $::osfamily {
    'RedHat': {
        file { '/usr/bin/fuel-logrotate':
          mode   => '0755',
          source => 'puppet:///modules/openstack/logrotate',
        }
    }
    'Debian': {
        file { '/usr/bin/fuel-logrotate':
          mode   => '0755',
          source => 'puppet:///modules/openstack/logrotate-ubuntu',
        }
    }
  }

  cron { 'fuel-logrotate':
    command => '/usr/bin/fuel-logrotate',
    user    => 'root',
    minute  => '*/30',
    require => File['/usr/bin/fuel-logrotate'],
  }
}
