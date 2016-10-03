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

  # Configure log rotation for other nodes
  file { $logrotatefile:
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('openstack/10-fuel.conf.erb'),
  }

  file { '/etc/logrotate.d/puppet':
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/openstack/logrotate-puppet.conf',
  }

  #Upstart logs are managed by fuel logrotate file
  file { "/etc/logrotate.d/upstart":
    ensure  => absent,
  }

  # TODO(aschultz): should move these to augeas when augeas is upgraded to
  # >=1.4.0 because maxsize isn't supported until 1.4.0 which breaks everything.
  File_line {
    ensure => 'present',
    path   => '/etc/logrotate.conf',
  }

  # We're  using after here to place these options above the include
  # /etc/logrotate.d as file_line does not have a before option.
  file_line { 'logrotate-tabooext':
    line  => 'tabooext + .nodaily',
    match => '^tabooext',
    after => '^create',
  } ->
  file_line { 'logrotate-compress':
    line  => 'compress',
    match => '^compress',
    after => '^tabooext',
  } ->
  file_line { 'logrotate-delaycompress':
    line  => 'delaycompress',
    match => '^delaycompress',
    after => '^compress',
  } ->
  file_line { 'logrotate-minsize':
    line  => "minsize ${minsize}",
    match => '^minsize',
    after => '^delaycompress',
  } ->
  file_line { 'logrotate-maxsize':
    line  => "maxsize ${maxsize}",
    match => '^maxsize',
    after => '^minsize',
  } ->
  file_line { 'logrotate-date-extension':
    line  => 'dateext',
    match => '^dateext',
    after => '^maxsize',
  } ->
  file_line { 'logrotate-date-format':
    line  => 'dateformat -%Y%m%d-%s',
    match => '^dateformat ',
    after => '^dateext',
  }

  if $debug {
    $interval = '10'
  } else {
    $interval = '30'
  }

  cron { 'fuel-logrotate':
    command     => '/usr/bin/fuel-logrotate',
    environment => [ 'MAILTO=""', 'PATH=/bin:/usr/bin:/usr/sbin' ],
    user        => 'root',
    minute      => "*/${interval}",
  }
}
