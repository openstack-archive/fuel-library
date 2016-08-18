# == Class: osnailyfacter::apache
#
#  Configure apache and listen ports. This class also manages the apache2
#  logrotate configuration.
#
# === Parameters
#
# [*purge_configs*]
#  (optional) Boolean flag to indicate if we should purge all the apache
#  configs unless explicitly managed via puppet.
#  Defaults to false
#
# [*listen_ports*]
#  (optional) The ports to listen on for apache
#  Defaults to '80'
#
# [*logrotate_rotate*]
#  (optional) The number of times to be rotated before being removed.
#  Defaults to '52'
#
# [*log_formats*]
#  (optional) Hash w/ additional `LogFormat` directives.
#  Defaults to {}
#
class osnailyfacter::apache (
  $purge_configs    = false,
  $listen_ports     = '80',
  $logrotate_rotate = '52',
  $log_formats      = {},
) {

  # define forwarded log format
  $log_format_forwarded = {
    'forwarded' => '%{X-Forwarded-For}i %l %u %t \"%r\" %s %b \"%{Referer}i\" \"%{User-agent}i\"'
  }

  $log_formats_mixed = merge($log_format_forwarded, $log_formats)

  class { '::apache':
    mpm_module       => false,
    default_vhost    => false,
    purge_configs    => $purge_configs,
    servername       => $::hostname,
    server_tokens    => 'Prod',
    server_signature => 'Off',
    trace_enable     => 'Off',
    log_formats      => $log_formats_mixed,
  }

  apache::listen { $listen_ports: }

  anchor { 'osnailyfacter::apache start' :} ->
  Apache::Listen[$listen_ports] ->
  Class['::apache'] ->
  anchor { 'osnailyfacter::apache end' :}

  # we need to override the logrotate file provided by apache to work around
  # wsgi issues on the restart caused by logrotate.
  # LP#1491576 and https://github.com/GrahamDumpleton/mod_wsgi/issues/81
  file { '/etc/logrotate.d/apache2':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('osnailyfacter/apache2.logrotate.erb'),
    require => Package['httpd']
  }

  # This will randomly rotate the array of delays based on hostname to allow
  # for an idempotent delay to be applied. This will introduce a delay between
  # 0 and 5 minutes to the logrotate process.
  $delay = fqdn_rotate([0,1,2,3,4,5], 'fuel-seed')

  # Convert delay into seconds for the prerotation script
  $apache2_logrotate_delay = $delay[0] * 60

  file { '/etc/logrotate.d/httpd-prerotate':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/etc/logrotate.d/httpd-prerotate/apache2':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('osnailyfacter/apache2.prerotate.erb'),
  }
}
