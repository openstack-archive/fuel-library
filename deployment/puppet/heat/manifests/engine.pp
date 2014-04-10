# Class heat::engine
#
#  Installs & configure the heat engine service
#
# == parameters
#  [*enabled*]
#    (optional) The state of the service
#    Defaults to true
#
#  [*heat_stack_user_role*]
#    (optional) Keystone role for heat template-defined users
#    Defaults to 'heat_stack_user'
#
#  [*heat_metadata_server_url*]
#    (optional) URL of the Heat metadata server
#    Defaults to 'http://127.0.0.1:8000'
#
#  [*heat_waitcondition_server_url*]
#    (optional) URL of the Heat waitcondition server
#    Defaults to 'http://127.0.0.1:8000/v1/waitcondition'
#
#  [*heat_watch_server_url*]
#    (optional) URL of the Heat cloudwatch server
#    Defaults to 'http://127.0.0.1:8003'
#
#  [*auth_encryption_key*]
#    (required) Encryption key used for authentication info in database
#
#  [*engine_life_check_timeout*]
#    (optional) RPC timeout (in seconds) for the engine liveness check that is
#    used for stack locking
#    Defaults to '2'
#

class heat::engine (
  $auth_encryption_key,
  $enabled                       = true,
  $heat_stack_user_role          = 'heat_stack_user',
  $heat_metadata_server_url      = 'http://127.0.0.1:8000',
  $heat_waitcondition_server_url = 'http://127.0.0.1:8000/v1/waitcondition',
  $heat_watch_server_url         = 'http://127.0.0.1:8003',
  $engine_life_check_timeout     = '2'
) {

  include heat::params

  Heat_config<||> ~> Service['heat-engine']

  Package['heat-engine'] -> Heat_config<||>
  Package['heat-engine'] -> Service['heat-engine']
  package { 'heat-engine':
    ensure => installed,
    name   => $::heat::params::engine_package_name,
  }

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  service { 'heat-engine':
    ensure     => $service_ensure,
    name       => $::heat::params::engine_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    require    => [ File['/etc/heat/heat.conf'],
                    Package['heat-common'],
                    Package['heat-engine']],
    subscribe  => Exec['heat-dbsync'],
  }

  heat_config {
    'DEFAULT/auth_encryption_key'          : value => $auth_encryption_key;
    'DEFAULT/heat_stack_user_role'         : value => $heat_stack_user_role;
    'DEFAULT/heat_metadata_server_url'     : value => $heat_metadata_server_url;
    'DEFAULT/heat_waitcondition_server_url': value => $heat_waitcondition_server_url;
    'DEFAULT/heat_watch_server_url'        : value => $heat_watch_server_url;
    'DEFAULT/engine_life_check_timeout'    : value => $engine_life_check_timeout;
  }
}
