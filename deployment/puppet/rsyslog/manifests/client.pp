# == Class: rsyslog::client
#
# Full description of class role here.
#
# === Parameters
#
# [*log_remote*]
# [*spool_size*]
# [*remote_type*]
# [*remote_forward_format*]
# [*log_local*]
# [*log_auth_local*]
# [*custom_config*]
# [*custom_params*]
# [*server*]
# [*port*]
# [*remote_servers*]
# [*ssl_ca*]
# [*log_templates*]
# [*actionfiletemplate*]
#
# === Variables
#
# === Examples
#
#  class { 'rsyslog::client': }
#
class rsyslog::client (
  $log_remote            = true,
  $spool_size            = '1g',
  $remote_type           = 'tcp',
  $remote_forward_format = 'RSYSLOG_ForwardFormat',
  $log_local             = false,
  $log_auth_local        = false,
  $custom_config         = undef,
  $custom_params         = undef,
  $server                = 'log',
  $port                  = '514',
  $remote_servers        = false,
  $ssl_ca                = undef,
  $log_templates         = false,
  $actionfiletemplate    = false
) inherits rsyslog {

  if $custom_config {
    $content_real = template($custom_config)
  } else {
    $content_real = template("${module_name}/client.conf.erb")
  }

  rsyslog::snippet { $rsyslog::client_conf:
    ensure  => present,
    content => $content_real,
  }

  if $rsyslog::ssl and $ssl_ca == undef {
    fail('You need to define $ssl_ca in order to use SSL.')
  }

  if $rsyslog::ssl and $remote_type != 'tcp' {
    fail('You need to enable tcp in order to use SSL.')
  }

}
