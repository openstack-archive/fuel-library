$verbose = true
$debug = true

Exec {
  logoutput => true,
  path => '/usr/sbin:/usr/bin:/sbin:/bin' 
}


stage { 'openstack-custom-repo': before => Stage['main'] }

$openstack_savanna_repo_name   = 'savanna-repo'
$openstack_savanna_repo        = 'http://172.18.196.75/savanna/'

define openstack_custom_repos (
  $openstack_repo_name = undef,
  $openstack_repo = undef,
) {
    if ($openstack_repo_name) {
      yumrepo { $openstack_repo_name:
        descr      => 'OpenStack packages',
        baseurl    => $openstack_repo,
        gpgcheck   => '0',
        priority   => '1'
      }
    }
}


openstack_custom_repos { 'savanna':
  openstack_repo => $openstack_savanna_repo,
  openstack_repo_name => $openstack_savanna_repo_name,
}

node "ppconroller1.kha.mirantis.net"  {

  class { 'mysql::server':
    package_name            => 'MySQL-server-5.5.28-6.x86_64',
    package_ensure          => 'present',
    service_name            => 'mysql',
    enabled                 => true,
    mysql_skip_name_resolve => false,
    use_syslog              => false,
  }

############  SAVANNA  ########################################################
#
  $savanna_api_bind_port                = '8386'
  $savanna_enabled                      = true
  $savanna_keystone_host                = '127.0.0.1'
  $savanna_keystone_port                = '35357'
  $savanna_keystone_protocol            = 'http'
  $savanna_keystone_user                = 'admin'
  $savanna_keystone_tenant              = 'admin'
  $savanna_keystone_password            = 'admin'
  $savanna_use_floading_ips             = 'False'
  $savanna_node_domain                  = 'novalocal'
  $savanna_plugins                      = 'vanilla'
  $savanna_vanilla_plugin_plugin_class  = 'savanna.plugins.vanilla.plugin:VanillaProvider'
  $savanna_db_password                  = 'savanna'
  $savanna_db_name                      = 'savanna'
  $savanna_db_user                      = 'savanna'
  $savanna_sql_connection               = "mysql://${$savanna_db_user}:${savanna_db_password}@localhost/${savanna_db_password}"

#
#### create the database
  class { 'savanna::db::mysql':
    password                            => $savanna_db_password,
    dbname                              => $savanna_db_name,
    user                                => $savanna_db_user,
  }

  class { 'savanna::api':
    enabled                             => $savanna_enabled,
    keystone_host                       => $savanna_keystone_host,
    keystone_port                       => $savanna_keystone_port,
    keystone_protocol                   => $savanna_keystone_protocol,
    keystone_user                       => $savanna_keystone_user,
    keystone_tenant                     => $savanna_keystone_tenant,
    keystone_password                   => $savanna_keystone_password,
    bind_port                           => $savanna_api_bind_port,
    use_floading_ips                    => $savanna_use_floading_ips,
    node_domain                         => $savanna_node_domain,
    plugins                             => $savanna_plugins,
    vanilla_plugin_plugin_class         => $savanna_vanilla_plugin_plugin_class,
    sql_connection                      => $savanna_sql_connection,
   }
}
