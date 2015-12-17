#
# == Class: openstack::heat
#
# Installs and configures Heat
#
# === Parameters
#
# [heat_protocol]
#   Protocol to use for reach Heat-related services.
#   Optional. Defaults to 'http'.
#
#
#TODO(bogdando) sync extended qpid rpc backend configuration here as well
# [use_stderr] Rather or not service should send output to stderr. Optional. Defaults to true.
#
# [*auth_uri*]
#  (optional) The public auth identity uri for the heat service
#  Should be used instead of keystone_{host,port,protocol}
#  Defaults to false
#
# [*identity_uri*]
#  (optional) The admin identity url for the heat service
#  Should be used instead of keystone_{host,port,protocol}
#  Defaults to false
#
# [*sql_connection*]
#  (optional) Connection string for database backend.
#  Defaults to 'mysql://heat:heat@localhost/heat'
#
# === Deprecated
#
# [*keystone_host*]
#  DEPRECATED. (optional) Old keystone host used to construct urls. Use auth_uri and
#  identity_uri instead.
#  Defaults to false
#
class openstack::heat (
  $external_ip                   = '127.0.0.1',
  $enabled                       = true,

  $keystone_auth                 = true,
  $keystone_host                 = false,
  $keystone_port                 = '35357',
  $keystone_service_port         = '5000',
  $keystone_protocol             = 'http',
  $keystone_user                 = 'heat',
  $keystone_tenant               = 'services',
  $keystone_password             = false,
  $keystone_ec2_uri              = false,
  $region                        = 'RegionOne',
  $auth_uri                      = false,
  $identity_uri                  = false,
  $heat_protocol                 = 'http',
  $trusts_delegated_roles        = [],

  $primary_controller            = false,
  $verbose                       = false,
  $debug                         = false,
  $default_log_levels            = undef,
  $use_syslog                    = false,
  $use_stderr                    = true,
  $syslog_log_facility           = 'LOG_LOCAL0',
  $log_dir                       = '/var/log/heat',

  $rpc_backend                   = 'rabbit',
  $amqp_hosts                    = ['127.0.0.1:5672'],
  $amqp_user                     = 'heat',
  $amqp_password                 = false,
  $rabbit_virtualhost            = '/',

  $heat_stack_user_role          = 'heat_stack_user',
  $heat_metadata_server_url      = false,
  $heat_waitcondition_server_url = false,
  $heat_watch_server_url         = false,
  $auth_encryption_key           = '%ENCRYPTION_KEY%',

  $sql_connection                = 'mysql://heat:heat@localhost/heat',
  $db_allowed_hosts              = ['localhost','%'],
  $idle_timeout                  = '3600',
  $max_pool_size                 = '10',
  $max_overflow                  = '30',
  $max_retries                   = '-1',

  $ic_https_validate_certs       = '1',
  $ic_is_secure                  = '0',

  $api_bind_host                 = '0.0.0.0',
  $api_bind_port                 = '8004',
  $api_cfn_bind_host             = '0.0.0.0',
  $api_cfn_bind_port             = '8000',
  $api_cloudwatch_bind_host      = '0.0.0.0',
  $api_cloudwatch_bind_port      = '8003',
){

  # No empty passwords allowed
  validate_string($amqp_password)

  # Generate values logic
  if $keystone_ec2_uri {
    $keystone_ec2_uri_real    = $keystone_ec2_uri
  } else {
    $keystone_ec2_uri_real    = "${keystone_protocol}://${keystone_host}:${keystone_port}/v2.0/ec2tokens"
  }
  if $heat_metadata_server_url {
    $metadata_server_url      = $heat_metadata_server_url
  } else {
    $metadata_server_url      = "${heat_protocol}://${external_ip}:${api_cfn_bind_port}"
  }
  if $heat_waitcondition_server_url {
    $waitcondition_server_url = $heat_waitcondition_server_url
  } else {
    $waitcondition_server_url = "${heat_protocol}://${external_ip}:${api_cfn_bind_port}/v1/waitcondition"
  }
  if $heat_watch_server_url {
    $watch_server_url         = $heat_watch_server_url
  } else {
    $watch_server_url         = "${heat_protocol}://${external_ip}:${api_cloudwatch_bind_port}"
  }

  # TODO(bogdando) clarify this config section (left from upstream presync state)
  heat_config {
    'DEFAULT/instance_connection_https_validate_certificates' : value => $ic_https_validate_certs;
    'DEFAULT/instance_connection_is_secure'                   : value => $ic_is_secure;
  }
  Package<| title == 'heat-api-cfn' or title == 'heat-api-cloudwatch' |>
  Heat_config <|
    title == 'DEFAULT/instance_connection_https_validate_certificates' or
    title == 'DEFAULT/instance_connection_is_secure'
  |> ->
  Service<| title == 'heat-api-cfn' or title == 'heat-api-cloudwatch' |>

  # Syslog configuration
  if $use_syslog {
    heat_config {
      'DEFAULT/use_syslog_rfc_format': value => true;
    }
  }

  # Common configuration, logging and RPC
  class { '::heat':
    auth_uri              => $auth_uri,
    identity_uri          => $identity_uri,
    keystone_ec2_uri      => $keystone_ec2_uri_real,
    keystone_host         => $keystone_host,
    keystone_port         => $keystone_port,
    keystone_protocol     => $keystone_protocol,
    keystone_user         => $keystone_user,
    keystone_tenant       => $keystone_tenant,
    keystone_password     => $keystone_password,
    region_name           => $region,

    sql_connection        => $sql_connection,
    database_idle_timeout => $idle_timeout,
    sync_db               => $primary_controller,

    rpc_backend           => $rpc_backend,
    rpc_response_timeout  => '600',
    rabbit_hosts          => $amqp_hosts,
    rabbit_userid         => $amqp_user,
    rabbit_password       => $amqp_password,
    rabbit_virtual_host   => $rabbit_virtualhost,

    log_dir               => $log_dir,
    verbose               => $verbose,
    debug                 => $debug,
    use_syslog            => $use_syslog,
    use_stderr            => $use_stderr,
    log_facility          => $syslog_log_facility,
  }

  # TODO (iberezovskiy): Move to globals (as it is done for sahara)
  # after new sync with upstream because of
  # https://github.com/openstack/puppet-heat/blob/master/manifests/init.pp#L305
  class { '::heat::logging':
    default_log_levels => $default_log_levels,
  }

  heat_config {
    'DEFAULT/max_template_size':       value => '5440000';
    'DEFAULT/max_json_body_size':      value => '10880000';
    'DEFAULT/max_resources_per_stack': value => '20000';
  }

  heat_config {
    'DEFAULT/notification_driver': value => 'heat.openstack.common.notifier.rpc_notifier';
    'DATABASE/max_pool_size':      value => $max_pool_size;
    'DATABASE/max_overflow':       value => $max_overflow;
    'DATABASE/max_retries':        value => $max_retries;
  }

  # Engine
  class { 'heat::engine' :
    auth_encryption_key           => $auth_encryption_key,
    heat_stack_user_role          => $heat_stack_user_role,
    heat_metadata_server_url      => $metadata_server_url,
    heat_waitcondition_server_url => $waitcondition_server_url,
    heat_watch_server_url         => $watch_server_url,
    trusts_delegated_roles        => $trusts_delegated_roles,
  }

  # Install the heat APIs
  class { 'heat::api':
    bind_host => $api_bind_host,
    bind_port => $api_bind_port,
    enabled   => $enabled,
  }
  class { 'heat::api_cfn' :
    bind_host => $api_cfn_bind_host,
    bind_port => $api_cfn_bind_port,
    enabled   => $enabled,
  }
  class { 'heat::api_cloudwatch' :
    bind_host => $api_cloudwatch_bind_host,
    bind_port => $api_cloudwatch_bind_port,
    enabled   => $enabled,
  }

  # Client
  class { 'heat::client' :  }
}
