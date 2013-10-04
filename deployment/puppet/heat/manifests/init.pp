class heat(
  $heat_enabled                  = true,
  $heat_db_user                  = 'heat',
  $heat_db_password              = 'heat',
  $heat_db_host                  = '127.0.0.1',
  $heat_db_name                  = 'heat',
  $heat_keystone_host            = '127.0.0.1',
  $heat_keystone_port            = '35357',
  $heat_keystone_protocol        = 'http',
  $heat_keystone_user            = 'heat',
  $heat_keystone_tenant          = 'services',
  $heat_keystone_password        = 'heat',
  $heat_keystone_ec2_uri         = 'http://127.0.0.1:5000/v2.0/ec2tokens',
  $heat_auth_uri                 = 'http://127.0.0.1:5000/v2.0',
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

  # Please use external IPs here
  $heat_stack_user_role          = 'heat_stack_user',
  $heat_metadata_server_url      = 'http://127.0.0.1:8000',
  $heat_waitcondition_server_url = 'http://127.0.0.1:8000/v1/waitcondition',
  $heat_watch_server_url         = 'http://127.0.0.1:8003',

  $heat_rabbit_hosts             = '127.0.0.1',
  $heat_rabbit_host              = '127.0.0.1',
  $heat_rabbit_userid            = 'nova',
  $heat_rabbit_ha_queues         = 'False',
  $heat_rabbit_password          = 'nova',
  $heat_rabbit_virtualhost       = '/',
  $heat_rabbit_port              = '5672',

  $heat_rpc_backend =  'heat.openstack.common.rpc.impl_kombu',
) {

  class { 'heat::db::mysql' :
    password => $heat_db_password,
  }

  class { 'heat::install' :
  }

  class { 'heat::cli' :
  }

  class { 'heat::client' :
  }

  class { 'heat::engine' :
    enabled                        => $heat_enabled,
    keystone_host                  => $heat_keystone_host,
    keystone_port                  => $heat_keystone_port,
    keystone_protocol              => $heat_keystone_protocol,
    keystone_user                  => $heat_keystone_user,
    keystone_tenant                => $heat_keystone_tenant,
    keystone_password              => $heat_keystone_password,
    bind_host                      => $heat_engine_bind_host,
    bind_port                      => $heat_engine_bind_port,
    heat_stack_user_role           => $heat_stack_user_role,
    heat_metadata_server_url       => $heat_metadata_server_url,
    heat_waitcondition_server_url  => $heat_waitcondition_server_url,
    heat_watch_server_url          => $heat_watch_server_url,
    verbose                        => $heat_verbose,
    debug                          => $heat_debug,

    rabbit_host                    => $heat_rabbit_host,
    rabbit_userid                  => $heat_rabbit_userid,
    rabbit_ha_queues               => $heat_rabbit_ha_queues,
    rabbit_password                => $heat_rabbit_password,
    rabbit_virtualhost             => $heat_rabbit_virtualhost,
    rabbit_port                    => $heat_rabbit_port,
    rpc_backend                    => $heat_rpc_backend,
  }

  class { 'heat::api' :
    enabled                        => $heat_enabled,
    keystone_host                  => $heat_keystone_host,
    keystone_port                  => $heat_keystone_port,
    keystone_protocol              => $heat_keystone_protocol,
    keystone_user                  => $heat_keystone_user,
    keystone_tenant                => $heat_keystone_tenant,
    keystone_password              => $heat_keystone_password,
    keystone_ec2_uri               => $heat_keystone_ec2_uri,
    auth_uri                       => $heat_auth_uri,
    bind_host                      => $heat_api_bind_host,
    bind_port                      => $heat_api_bind_port,
    verbose                        => $heat_verbose,
    debug                          => $heat_debug,

    rabbit_host                    => $heat_rabbit_host,
    rabbit_userid                  => $heat_rabbit_userid,
    rabbit_ha_queues               => $heat_rabbit_ha_queues,
    rabbit_password                => $heat_rabbit_password,
    rabbit_virtualhost             => $heat_rabbit_virtualhost,
    rabbit_port                    => $heat_rabbit_port,
    rpc_backend                    => $heat_rpc_backend,
  }

  class { 'heat::keystone::auth' :
    password                       => 'heat',
    auth_name                      => 'heat',
    public_address                 => '127.0.0.1',
    admin_address                  => '127.0.0.2',
    internal_address               => '127.0.0.3',
    heat_port                      => '8004',
    region                         => 'RegionOne',
    tenant                         => 'services',
    email                          => 'heat@mirantis.com',
  }

  class { 'heat::db' :
    sql_connection                 => "mysql://${heat_db_user}:${heat_db_password}@${heat_db_host}/${heat_db_name}"
  }

  class { 'heat::api_cfn' :
    enabled                       => $heat_enabled,
    keystone_host                 => $heat_keystone_host,
    keystone_port                 => $heat_keystone_port,
    keystone_protocol             => $heat_keystone_protocol,
    keystone_user                 => $heat_keystone_user,
    keystone_tenant               => $heat_keystone_tenant,
    keystone_password             => $heat_keystone_password,
    keystone_ec2_uri              => $heat_keystone_ec2_uri,
    auth_uri                      => $heat_auth_uri,
    bind_host                     => $heat_api_cfn_bind_host,
    bind_port                     => $heat_api_cfn_bind_port,
    verbose                       => $heat_verbose,
    debug                         => $heat_debug,

    rabbit_host                   => $heat_rabbit_host,
    rabbit_userid                 => $heat_rabbit_userid,
    rabbit_ha_queues              => $heat_rabbit_ha_queues,
    rabbit_password               => $heat_rabbit_password,
    rabbit_virtualhost            => $heat_rabbit_virtualhost,
    rabbit_port                   => $heat_rabbit_port,
    rpc_backend                   => $heat_rpc_backend,
  }

  class { 'heat::api_cloudwatch' :
    enabled                       => $heat_enabled,
    keystone_host                 => $heat_keystone_host,
    keystone_port                 => $heat_keystone_port,
    keystone_protocol             => $heat_keystone_protocol,
    keystone_user                 => $heat_keystone_user,
    keystone_tenant               => $heat_keystone_tenant,
    keystone_password             => $heat_keystone_password,
    keystone_ec2_uri              => $heat_keystone_ec2_uri,
    auth_uri                      => $heat_auth_uri,
    bind_host                     => $heat_api_cloudwatch_bind_host,
    bind_port                     => $heat_api_cloudwatch_bind_port,
    verbose                       => $heat_verbose,
    debug                         => $heat_debug,

    rabbit_host                   => $heat_rabbit_host,
    rabbit_userid                 => $heat_rabbit_userid,
    rabbit_ha_queues              => $heat_rabbit_ha_queues,
    rabbit_password               => $heat_rabbit_password,
    rabbit_virtualhost            => $heat_rabbit_virtualhost,
    rabbit_port                   => $heat_rabbit_port,
    rpc_backend                   => $heat_rpc_backend,
  }

}
