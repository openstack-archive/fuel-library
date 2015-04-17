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
  $logrotatefile = '/etc/logrotate.d/fuel.conf'

  if $role == 'server' {
    # Configure log rotation for master node and docker containers
    file { '/etc/logrotate.d/fuel.conf':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('openstack/10-fuel-docker.conf.erb'),
    }
  } else {
    # Configure log rotation for other nodes
    file { '/etc/logrotate.d/fuel.conf':
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
  if $::osfamily == 'RedHat' {
      # Due to bug in logrotate, it always returns 0. Use grep to detect errors
      # in output; exit code 1 is considered success as no errors were emitted.
      exec {'logrotate_check':
        path    => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
        command => "logrotate ${logrotatefile} >& /tmp/logrotate && grep -q error /tmp/logrotate",
        returns => 1,
        require => File[$logrotatefile],
    }
  }
}
