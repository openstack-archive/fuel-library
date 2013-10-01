# Installs & configure the savanna API service

class savanna::api (
  $enabled            = true,
  $keystone_host      = '127.0.0.1',
  $keystone_port      = '35357',
  $keystone_protocol  = 'http',
  $keystone_user      = 'admin',
  $keystone_tenant    = 'services',
  $keystone_password  = false,
  $bind_port          = '8386',
  $use_floading_ips   = 'False',
  $node_domain        = 'novalocal',
  $plugins            = 'vanilla',
  $vanilla_plugin_plugin_class = 'savanna.plugins.vanilla.plugin:VanillaProvider',
  $sql_connection         = 'mysql://savanna:savanna@localhost/savanna',
) {

  include savanna::params

  validate_string($keystone_password)

  package { 'savanna':
    ensure => installed,
    name   => $::savanna::params::savanna_package_name,
  }

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  service { 'savanna-api':
    ensure     => $service_ensure,
    name       => $::savanna::params::savanna_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    require    => Package['savanna'],
  }

  savanna_config {
    'DEFAULT/os_admin_tenant_name'         : value => $keystone_tenant;
    'DEFAULT/os_admin_user'                : value => $keystone_user;
    'DEFAULT/os_admin_password'            : value => $keystone_password;
    'DEFAULT/os_auth_host'                 : value => $keystone_host;
    'DEFAULT/os_auth_port'                 : value => $keystone_port;
    'DEFAULT/use_floating_ips'             : value => $use_floading_ips;
    'DEFAULT/node_domain'                  : value => $node_domain;
    'DEFAULT/plugins'                      : value => $plugins;
    'plugin:vanilla/plugin_class'          : value => $vanilla_plugin_plugin_class;
    'database/connection'                  : value => $sql_connection;
  }

  Package['savanna'] -> Savanna_config<||> -> Service['savanna-api']

}
