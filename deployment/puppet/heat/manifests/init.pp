class heat(
  $pacemaker                = false,
  $external_ip              = '127.0.0.1',

  $keystone_host            = '127.0.0.1',
  $keystone_port            = '5000',
  $keystone_protocol        = 'http',
  $keystone_user            = 'heat',
  $keystone_tenant          = 'services',
  $keystone_password        = 'heat',

  $db_user                  = 'heat',
  $db_password              = 'heat',
  $db_host                  = '127.0.0.1',
  $db_name                  = 'heat',
  $db_allowed_hosts         = ['localhost','%'],

  $api_cfn_bind_host        = '0.0.0.0',
  $api_cfn_bind_port        = '8000',
  $engine_bind_host         = '0.0.0.0',
  $engine_bind_port         = '8001',
  $api_cloudwatch_bind_host = '0.0.0.0',
  $api_cloudwatch_bind_port = '8003',
  $api_bind_host            = '0.0.0.0',
  $api_bind_port            = '8004',
  $rpc_backend              = 'heat.openstack.common.rpc.impl_kombu',
  $stack_user_role          = 'heat_stack_user',

  $debug                    = false,
  $verbose                  = false,
  $use_syslog               = false,
  $syslog_log_facility      = 'LOG_LOCAL0',
  $log_dir                  = '/var/log/heat',

  $amqp_hosts               = '127.0.0.1',
  $amqp_user                = 'heat',
  $amqp_password            = 'heat',
  $rabbit_ha_queues         = false,
  $rabbit_virtualhost       = '/',
) {

  validate_string($keystone_password)
  validate_string($rabbit_password)
  validate_string($db_password)

  $keystone_ec2_uri         = "${keystone_protocol}://${keystone_host}:${keystone_port}/v2.0/ec2tokens"
  $auth_uri                 = "${keystone_protocol}://${keystone_host}:${keystone_port}/v2.0"
  $metadata_server_url      = "http://${external_ip}:${api_cfn_bind_port}"
  $waitcondition_server_url = "http://${external_ip}:${api_cfn_bind_port}/v1/waitcondition"
  $watch_server_url         = "http://${external_ip}:${api_cloudwatch_bind_port}"

  class { 'heat::db::mysql' :
    password                     => $db_password,
    dbname                       => $db_name,
    user                         => $db_user,
    dbhost                       => $db_host,
    allowed_hosts                => $db_allowed_hosts,
  }

  class { 'heat::install' :
    keystone_host                  => $keystone_host,
    keystone_port                  => $keystone_port,
    keystone_protocol              => $keystone_protocol,
    keystone_user                  => $keystone_user,
    keystone_tenant                => $keystone_tenant,
    keystone_password              => $keystone_password,
    heat_stack_user_role           => $stack_user_role,
    heat_metadata_server_url       => $metadata_server_url,
    heat_waitcondition_server_url  => $waitcondition_server_url,
    heat_watch_server_url          => $watch_server_url,
    verbose                        => $verbose,
    debug                          => $debug,
    use_syslog                     => $use_syslog,
    syslog_log_facility            => $syslog_log_facility,
    log_dir                        => $log_dir,
    rpc_backend                    => $rpc_backend,
    amqp_hosts                     => $amqp_hosts,
    amqp_user                      => $amqp_user,
    amqp_password                  => $amqp_password,
    rabbit_ha_queues               => $rabbit_ha_queues,
    rabbit_virtualhost             => $rabbit_virtualhost,
    api_bind_host                  => $api_bind_host,
    api_bind_port                  => $api_bind_port,
    api_cfn_bind_host              => $api_cfn_bind_host,
    api_cfn_bind_port              => $api_cfn_bind_port,
    api_cloudwatch_bind_host       => $api_cloudwatch_bind_host,
    api_cloudwatch_bind_port       => $api_cloudwatch_bind_port,
  }

  class { 'heat::client' :
  }

  class { 'heat::engine' :
    pacemaker                      => $pacemaker,
  }

  class { 'heat::api' :
    bind_host                      => $api_bind_host,
    bind_port                      => $api_bind_port,
  }

  class { 'heat::keystone::auth' :
    password                       => 'heat',
    auth_name                      => 'heat',
    public_address                 => $external_ip,
    admin_address                  => $keystone_host,
    internal_address               => $keystone_host,
    heat_port                      => '8004',
    region                         => 'RegionOne',
    tenant                         => 'services',
    email                          => 'heat@mirantis.com',
  }

  class { 'heat::db' :
    sql_connection                 => "mysql://${db_user}:${db_password}@${db_host}/${db_name}?read_timeout=60",
  }

  class { 'heat::api_cfn' :
    bind_host                     => $api_cfn_bind_host,
    bind_port                     => $api_cfn_bind_port,
  }

  class { 'heat::api_cloudwatch' :
    bind_host                     => $api_cloudwatch_bind_host,
    bind_port                     => $api_cloudwatch_bind_port,
  }

}
