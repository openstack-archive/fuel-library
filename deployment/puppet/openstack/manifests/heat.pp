#
#TODO(bogdando) sync extended qpid rpc backend configuration here as well

class openstack::heat (
  $pacemaker                     = false,
  $external_ip                   = '127.0.0.1',
  $enabled                       = true,

  $keystone_host                 = '127.0.0.1',
  $keystone_port                 = '35357',
  $keystone_service_port         = '5000',
  $keystone_protocol             = 'http',
  $keystone_user                 = 'heat',
  $keystone_tenant               = 'services',
  $keystone_password             = false,
  $keystone_ec2_uri              = false,
  $auth_uri                      = false,

  $verbose                       = false,
  $debug                         = false,
  $use_syslog                    = false,
  $syslog_log_facility           = 'LOG_LOCAL0',
  $log_dir                       = '/var/log/heat',

  $rpc_backend                   = 'heat.openstack.common.rpc.impl_kombu',
  $amqp_hosts                    = ['127.0.0.1:5672'],
  $amqp_user                     = 'heat',
  $amqp_password                 = false,
  $rabbit_virtualhost            = '/',

  $heat_stack_user_role          = 'heat_stack_user',
  $heat_metadata_server_url      = false,
  $heat_waitcondition_server_url = false,
  $heat_watch_server_url         = false,
  $auth_encryption_key           = '%ENCRYPTION_KEY%',

  $sql_connection                = false,
  $db_user                       = 'heat',
  $db_password                   = false,
  $db_host                       = '127.0.0.1',
  $db_name                       = 'heat',
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
  $primary_controller            = false,
){

  # No empty passwords allowed
  validate_string($keystone_password)
  validate_string($amqp_password)
  validate_string($db_password)

  # Generate values logic
  if $keystone_ec2_uri {
    $keystone_ec2_uri_real    = $keystone_ec2_uri
  } else {
    $keystone_ec2_uri_real    = "${keystone_protocol}://${keystone_host}:${keystone_port}/v2.0/ec2tokens"
  }
  if $auth_uri {
    $auth_uri_real            = $auth_uri
  } else {
    $auth_uri_real            = "${keystone_protocol}://${keystone_host}:${keystone_service_port}/v2.0"
  }
  if $heat_metadata_server_url {
    $metadata_server_url      = $heat_metadata_server_url
  } else {
    $metadata_server_url      = "http://${external_ip}:${api_cfn_bind_port}"
  }
  if $heat_waitcondition_server_url {
    $waitcondition_server_url = $heat_waitcondition_server_url
  } else {
    $waitcondition_server_url = "http://${external_ip}:${api_cfn_bind_port}/v1/waitcondition"
  }
  if $heat_watch_server_url {
    $watch_server_url         = $heat_watch_server_url
  } else {
    $watch_server_url         = "http://${external_ip}:${api_cloudwatch_bind_port}"
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

  # Firewall rules for APIs
  firewall { '206 heat-api-cloudwatch' :
    dport   => [ $api_cloudwatch_bind_port ],
    proto   => 'tcp',
    action  => 'accept',
  } ->
  firewall { '205 heat-api-cfn' :
    dport   => [ $api_cfn_bind_port ],
    proto   => 'tcp',
    action  => 'accept',
  } ->
  firewall { '204 heat-api' :
    dport   => [ $api_bind_port ],
    proto   => 'tcp',
    action  => 'accept',
  } ->

  # Follow the Heat installation order
  # DB
  class { 'heat::db::mysql':
    password                      => $db_password,
    dbname                        => $db_name,
    user                          => $db_user,
    host                          => $db_host,
    allowed_hosts                 => $db_allowed_hosts,
  }

  # Auth
  class { 'heat::keystone::auth' :
    password                       => $keystone_password,
    auth_name                      => $keystone_user,
    public_address                 => $external_ip,
    admin_address                  => $keystone_host,
    internal_address               => $keystone_host,
    port                           => '8004',
    version                        => 'v1',
    region                         => 'RegionOne',
    tenant                         => 'services',
    email                          => "${keystone_user}@localhost",
    public_protocol                => 'http',
    admin_protocol                 => 'http',
    internal_protocol              => 'http',
    configure_endpoint             => true,

  }
  #TODO(bogdando) clarify this new to Fuel Heat auth cfn patterns
  class { 'heat::keystone::auth_cfn' :
    password                       => $keystone_password,
    auth_name                      => "${keystone_user}-cfn",
    service_type                   => 'cloudformation',
    public_address                 => $external_ip,
    admin_address                  => $keystone_host,
    internal_address               => $keystone_host,
    port                           => '8000',
    version                        => 'v1',
    region                         => 'RegionOne',
    tenant                         => 'services',
    email                          => "${keystone_user}-cfn@localhost",
    public_protocol                => 'http',
    admin_protocol                 => 'http',
    internal_protocol              => 'http',
    configure_endpoint             => true,
  }

  # Common configuration, logging and RPC
  class { '::heat':
    auth_uri                      => $auth_uri_real,
    keystone_ec2_uri              => $keystone_ec2_uri_real,
    keystone_host                 => $keystone_host,
    keystone_port                 => $keystone_port,
    keystone_protocol             => $keystone_protocol,
    keystone_user                 => $keystone_user,
    keystone_tenant               => $keystone_tenant,
    keystone_password             => $keystone_password,

    sql_connection                => $sql_connection,
    database_idle_timeout         => $idle_timeout,

    rpc_backend                   => $rpc_backend,
    rabbit_hosts                  => $amqp_hosts,
    rabbit_userid                 => $amqp_user,
    rabbit_password               => $amqp_password,
    rabbit_virtual_host           => $rabbit_virtualhost,

    log_dir                       => $log_dir,
    verbose                       => $verbose,
    debug                         => $debug,
    use_syslog                    => $use_syslog,
    log_facility                  => $syslog_log_facility,
  }

  heat_config {
    'DEFAULT/notification_driver': value => 'heat.openstack.common.notifier.rpc_notifier';
    'DATABASE/max_pool_size':      value => $max_pool_size;
    'DATABASE/max_overflow':       value => $max_overflow;
    'DATABASE/max_retries':        value => $max_retries;
  }

  # Syslog configuration
  if $use_syslog {
    heat_config {
      'DEFAULT/use_syslog_rfc_format': value => true;
    }
  }

  $deps_routes_package_name     = 'python-routes'
  package { 'python-routes':
    ensure  => $ensure,
    name    => $deps_routes_package_name,
  } ->  Package <| title == 'heat-api' |>

  # Engine
  class { 'heat::engine' :
    pacemaker                     => $pacemaker,
    primary_controller            => $primary_controller,
    auth_encryption_key           => $auth_encryption_key,
    heat_stack_user_role          => $heat_stack_user_role,
    heat_metadata_server_url      => $metadata_server_url,
    heat_waitcondition_server_url => $waitcondition_server_url,
    heat_watch_server_url         => $watch_server_url,
  }

  # Install the heat APIs
  class { 'heat::api':
    bind_host                     => $api_bind_host,
    bind_port                     => $api_bind_port,
    enabled                       => $enabled,
  }
  class { 'heat::api_cfn' :
    bind_host                     => $api_cfn_bind_host,
    bind_port                     => $api_cfn_bind_port,
    enabled                       => $enabled,
  }
  class { 'heat::api_cloudwatch' :
    bind_host                     => $api_cloudwatch_bind_host,
    bind_port                     => $api_cloudwatch_bind_port,
    enabled                       => $enabled,
  }

  # Client
  class { 'heat::client' :  }

  # Patching openstack related notifications
  Package<| title == 'heat-engine'|> ~> Service<| title == 'heat-engine_service'|>
  if !defined(Service['heat-engine']) {
    notify{ "Module ${module_name} cannot notify service heat-engine on package update": }
  }
  Package<| title == 'heat-api'|> ~> Service<| title == 'heat-api'|>
  if !defined(Service['heat-api']) {
    notify{ "Module ${module_name} cannot notify service heat-api on package update": }
  }
  Package<| title == 'heat-api-cfn'|> ~> Service<| title == 'heat-api-cfn'|>
  if !defined(Service['heat-api-cfn']) {
    notify{ "Module ${module_name} cannot notify service heat-api-cfn on package update": }
  }
  Package<| title == 'heat-api-cloudwatch'|> ~> Service<| title == 'heat-api-cloudwatch'|>
  if !defined(Service['heat-api-cloudwatch']) {
    notify{ "Module ${module_name} cannot notify service heat-api-cloudwatch on package update": }
  }
}
