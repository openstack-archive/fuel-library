# Class cinder::logging
#
#  cinder extended logging configuration
#
# == parameters
#
#  [*logging_context_format_string*]
#    (optional) Format string to use for log messages with context.
#    Defaults to undef.
#    Example: '%(asctime)s.%(msecs)03d %(process)d %(levelname)s %(name)s\
#              [%(request_id)s %(user_identity)s] %(instance)s%(message)s'
#
#  [*logging_default_format_string*]
#    (optional) Format string to use for log messages without context.
#    Defaults to undef.
#    Example: '%(asctime)s.%(msecs)03d %(process)d %(levelname)s %(name)s\
#              [-] %(instance)s%(message)s'
#
#  [*logging_debug_format_suffix*]
#    (optional) Formatted data to append to log format when level is DEBUG.
#    Defaults to undef.
#    Example: '%(funcName)s %(pathname)s:%(lineno)d'
#
#  [*logging_exception_prefix*]
#    (optional) Prefix each line of exception output with this format.
#    Defaults to undef.
#    Example: '%(asctime)s.%(msecs)03d %(process)d TRACE %(name)s %(instance)s'
#
#  [*log_config_append*]
#    The name of an additional logging configuration file.
#    Defaults to undef.
#    See https://docs.python.org/2/howto/logging.html
#
#  [*default_log_levels*]
#    (optional) Hash of logger (keys) and level (values) pairs.
#    Defaults to undef.
#    Example:
#      { 'amqp' => 'WARN', 'amqplib' => 'WARN', 'boto' => 'WARN',
#        'qpid' => 'WARN', 'sqlalchemy' => 'WARN', 'suds' => 'INFO',
#        'iso8601' => 'WARN',
#        'requests.packages.urllib3.connectionpool' => 'WARN' }
#
#  [*publish_errors*]
#    (optional) Publish error events (boolean value).
#    Defaults to undef (false if unconfigured).
#
#  [*fatal_deprecations*]
#    (optional) Make deprecations fatal (boolean value)
#    Defaults to undef (false if unconfigured).
#
#  [*instance_format*]
#    (optional) If an instance is passed with the log message, format it
#               like this (string value).
#    Defaults to undef.
#    Example: '[instance: %(uuid)s] '
#
#  [*instance_uuid_format*]
#    (optional) If an instance UUID is passed with the log message, format
#               it like this (string value).
#    Defaults to undef.
#    Example: instance_uuid_format='[instance: %(uuid)s] '

#  [*log_date_format*]
#    (optional) Format string for %%(asctime)s in log records.
#    Defaults to undef.
#    Example: 'Y-%m-%d %H:%M:%S'

class cinder::logging(
  $logging_context_format_string = undef,
  $logging_default_format_string = undef,
  $logging_debug_format_suffix   = undef,
  $logging_exception_prefix      = undef,
  $log_config_append             = undef,
  $default_log_levels            = undef,
  $publish_errors                = undef,
  $fatal_deprecations            = undef,
  $instance_format               = undef,
  $instance_uuid_format          = undef,
  $log_date_format               = undef,
) {

  if $logging_context_format_string {
    cinder_config {
      'DEFAULT/logging_context_format_string' :
        value => $logging_context_format_string;
      }
    }
  else {
    cinder_config {
      'DEFAULT/logging_context_format_string' : ensure => absent;
      }
    }

  if $logging_default_format_string {
    cinder_config {
      'DEFAULT/logging_default_format_string' :
        value => $logging_default_format_string;
      }
    }
  else {
    cinder_config {
      'DEFAULT/logging_default_format_string' : ensure => absent;
      }
    }

  if $logging_debug_format_suffix {
    cinder_config {
      'DEFAULT/logging_debug_format_suffix' :
        value => $logging_debug_format_suffix;
      }
    }
  else {
    cinder_config {
      'DEFAULT/logging_debug_format_suffix' : ensure => absent;
      }
    }

  if $logging_exception_prefix {
    cinder_config {
      'DEFAULT/logging_exception_prefix' : value => $logging_exception_prefix;
      }
    }
  else {
    cinder_config {
      'DEFAULT/logging_exception_prefix' : ensure => absent;
      }
    }

  if $log_config_append {
    cinder_config {
      'DEFAULT/log_config_append' : value => $log_config_append;
      }
    }
  else {
    cinder_config {
      'DEFAULT/log_config_append' : ensure => absent;
      }
    }

  if $default_log_levels {
    cinder_config {
      'DEFAULT/default_log_levels' :
        value => join(sort(join_keys_to_values($default_log_levels, '=')), ',');
      }
    }
  else {
    cinder_config {
      'DEFAULT/default_log_levels' : ensure => absent;
      }
    }

  if $publish_errors {
    cinder_config {
      'DEFAULT/publish_errors' : value => $publish_errors;
      }
    }
  else {
    cinder_config {
      'DEFAULT/publish_errors' : ensure => absent;
      }
    }

  if $fatal_deprecations {
    cinder_config {
      'DEFAULT/fatal_deprecations' : value => $fatal_deprecations;
      }
    }
  else {
    cinder_config {
      'DEFAULT/fatal_deprecations' : ensure => absent;
      }
    }

  if $instance_format {
    cinder_config {
      'DEFAULT/instance_format' : value => $instance_format;
      }
    }
  else {
    cinder_config {
      'DEFAULT/instance_format' : ensure => absent;
      }
    }

  if $instance_uuid_format {
    cinder_config {
      'DEFAULT/instance_uuid_format' : value => $instance_uuid_format;
      }
    }
  else {
    cinder_config {
      'DEFAULT/instance_uuid_format' : ensure => absent;
      }
    }

  if $log_date_format {
    cinder_config {
      'DEFAULT/log_date_format' : value => $log_date_format;
      }
    }
  else {
    cinder_config {
      'DEFAULT/log_date_format' : ensure => absent;
      }
    }


}
