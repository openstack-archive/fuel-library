class heat(
  $pacemaker                     = false,
  $external_ip                   = '127.0.0.1',

  $heat_keystone_host            = '127.0.0.1',
  $heat_keystone_port            = '5000',
  $heat_keystone_protocol        = 'http',
  $heat_keystone_user            = 'heat',
  $heat_keystone_tenant          = 'services',
  $heat_keystone_password        = 'heat',

  $heat_db_user                  = 'heat',
  $heat_db_password              = 'heat',
  $heat_db_host                  = '127.0.0.1',
  $heat_db_name                  = 'heat',
  $heat_db_allowed_hosts         = ['localhost','%'],

  $heat_api_cfn_bind_host        = '0.0.0.0',
  $heat_api_cfn_bind_port        = '8000',
  $heat_engine_bind_host         = '0.0.0.0',
  $heat_engine_bind_port         = '8001',
  $heat_api_cloudwatch_bind_host = '0.0.0.0',
  $heat_api_cloudwatch_bind_port = '8003',
  $heat_api_bind_host            = '0.0.0.0',
  $heat_api_bind_port            = '8004',
  $heat_debug                    = 'True',
  $heat_verbose                  = 'True',
  $heat_rpc_backend              = 'heat.openstack.common.rpc.impl_kombu',
  $heat_stack_user_role          = 'heat_stack_user',

  $heat_rabbit_host              = '127.0.0.1',
  $heat_rabbit_login             = 'heat',
  $heat_rabbit_ha_queues         = 'False',
  $heat_rabbit_password          = 'heat',
  $heat_rabbit_virtualhost       = '/',
  $heat_rabbit_port              = '5672',
  $heat_rabbit_queue_host        = 'heat',
) {

  $heat_keystone_ec2_uri         = "${heat_keystone_protocol}://${heat_keystone_host}:${heat_keystone_port}/v2.0/ec2tokens"
  $heat_auth_uri                 = "${heat_keystone_protocol}://${heat_keystone_host}:${heat_keystone_port}/v2.0"
  $heat_metadata_server_url      = "http://${external_ip}:${heat_api_cfn_bind_port}"
  $heat_waitcondition_server_url = "http://${external_ip}:${heat_api_cfn_bind_port}/v1/waitcondition"
  $heat_watch_server_url         = "http://${external_ip}:${heat_api_cloudwatch_bind_port}"

  class { 'heat::db::mysql' :
    password                     => $heat_db_password,
    dbname                       => $heat_db_name,
    user                         => $heat_db_user,
    dbhost                       => $heat_db_host,
    allowed_hosts                => $heat_db_allowed_hosts,
  }

  class { 'heat::install' :
    keystone_host                  => $heat_keystone_host,
    keystone_port                  => $heat_keystone_port,
    keystone_protocol              => $heat_keystone_protocol,
    keystone_user                  => $heat_keystone_user,
    keystone_tenant                => $heat_keystone_tenant,
    keystone_password              => $heat_keystone_password,
    heat_stack_user_role           => $heat_stack_user_role,
    heat_metadata_server_url       => $heat_metadata_server_url,
    heat_waitcondition_server_url  => $heat_waitcondition_server_url,
    heat_watch_server_url          => $heat_watch_server_url,
    verbose                        => $heat_verbose,
    debug                          => $heat_debug,
    rpc_backend                    => $heat_rpc_backend,
    rabbit_host                    => $heat_rabbit_host,
    rabbit_userid                  => $heat_rabbit_login,
    rabbit_ha_queues               => $heat_rabbit_ha_queues,
    rabbit_password                => $heat_rabbit_password,
    rabbit_virtualhost             => $heat_rabbit_virtualhost,
    rabbit_port                    => $heat_rabbit_port,
    rabbit_queue_host              => $heat_rabbit_queue_host,                                                 
    api_bind_host                  => $heat_api_bind_host,
    api_bind_port                  => $heat_api_bind_port,
    api_cfn_bind_host              => $heat_api_cfn_bind_host,
    api_cfn_bind_port              => $heat_api_cfn_bind_port,
    api_cloudwatch_bind_host       => $heat_api_cloudwatch_bind_host,
    api_cloudwatch_bind_port       => $heat_api_cloudwatch_bind_port,
  }

  class { 'heat::client' :
  }

  class { 'heat::engine' :
    pacemaker                      => $pacemaker,
  }

  class { 'heat::api' :
    bind_host                      => $heat_api_bind_host,
    bind_port                      => $heat_api_bind_port,
  }

  class { 'heat::keystone::auth' :
    password                       => 'heat',
    auth_name                      => 'heat',
    public_address                 => $external_ip,
    admin_address                  => $heat_keystone_host,
    internal_address               => $heat_keystone_host,
    heat_port                      => '8004',
    region                         => 'RegionOne',
    tenant                         => 'services',
    email                          => 'heat@mirantis.com',
  }

  class { 'heat::db' :
    sql_connection                 => "mysql://${heat_db_user}:${heat_db_password}@${heat_db_host}/${heat_db_name}",
  }

  class { 'heat::api_cfn' :
    bind_host                     => $heat_api_cfn_bind_host,
    bind_port                     => $heat_api_cfn_bind_port,
  }

  class { 'heat::api_cloudwatch' :
    bind_host                     => $heat_api_cloudwatch_bind_host,
    bind_port                     => $heat_api_cloudwatch_bind_port,
  }

}
