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

  # TODO(aschultz): should move these to augeas when augeas is upgraded to
  # >=1.4.0 because maxsize isn't supported until 1.4.0 which breaks everything.
  File_line {
    ensure => 'present',
    path   => '/etc/logrotate.conf',
  }
  file_line { 'logrotate-tabooext':
    line  => 'tabooext + .nodaily',
    match => '^tabooext',
  } ->
  file_line { 'logrotate-compress':
    line  => 'compress',
    match => '^compress',
  } ->
  file_line { 'logrotate-delaycompress':
    line  => 'delaycompress',
    match => '^delaycompress',
  } ->
  file_line { 'logrotate-minsize':
    line  => "minsize ${minsize}",
    match => '^minsize',
  } ->
  file_line { 'logrotate-maxsize':
    line   => "maxsize ${maxsize}",
    match  => '^maxsize'
  }

  cron { 'fuel-logrotate':
    command => '/usr/bin/fuel-logrotate',
    user    => 'root',
    minute  => '*/30',
  }
}
