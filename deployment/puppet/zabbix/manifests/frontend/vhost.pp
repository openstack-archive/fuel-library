# == Class: zabbix::frontend::vhost
#
class zabbix::frontend::vhost (
  $ensure   = $zabbix::params::frontend_ensure,
  $hostname = $zabbix::params::frontend_hostname,
  $docroot  = undef,
  $port     = $zabbix::params::frontend_port,
  $timezone = $zabbix::params::timezone) inherits zabbix::params {

  validate_re($ensure, [absent, present])
  validate_string($hostname)

  $docroot_real = $docroot ? {
    undef   => "/var/www/${hostname}/htdocs",
    default => $docroot
  }
  validate_absolute_path($docroot_real)

  if ($ensure == present) {
    include apache

    apache::vhost { $hostname:
      vhost_name => $hostname,
      docroot    => $docroot_real,
      port       => $port,
      ssl        => false
    }

    apache::vhost::include::php { 'zabbix':
      vhost_name => $hostname,
      values     => [
        "date.timezone \"${timezone}\"",
        'post_max_size "32M"',
        'max_execution_time "600"',
        'max_input_time "600"']
    }
  }
}
