class murano::repository (
    $verbose                        = 'True',
    $debug                          = 'True',
    $repository_host                = '0.0.0.0',
    $repository_port                = '8084',
    $repository_manifests           = 'Services',
    $repository_ui                  = 'ui_forms',
    $repository_workflows           = 'workflows',
    $repository_heat                = 'heat_templates',
    $repository_agent               = 'agent_templates',
    $repository_scripts             = 'scripts',
    $repository_output_ui           = 'service_forms',
    $repository_output_workflows    = 'workflows',
    $repository_output_heat         = 'templates/cf',
    $repository_output_agent        = 'templates/agent',
    $repository_output_scripts      = 'templates/agent/scripts',
    $repository_auth_host           = '127.0.0.1',
    $repository_auth_port           = '5000',
    $repository_auth_protocol       = 'http',
    $repository_admin_user          = 'admin',
    $repository_admin_password      = 'swordfish',
    $repository_admin_tenant_name   = 'admin',
) {

  include murano::params

  package { 'murano_repository':
    ensure => installed,
    name   => $::murano::params::murano_repository_package_name,
  }

  service { 'murano_repository':
    ensure     => 'running',
    name       => $::murano::params::murano_repository_service_name,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }

  murano_repository_config {
    'DEFAULT/host'                : value => $repository_host;
    'DEFAULT/port'                : value => $repository_port;
    'DEFAULT/manifests'           : value => $repository_manifests;
    'DEFAULT/ui'                  : value => $repository_ui;
    'DEFAULT/workflows'           : value => $repository_workflow;
    'DEFAULT/heat'                : value => $repository_heat;
    'DEFAULT/agent'               : value => $repository_agent;
    'DEFAULT/scripts'             : value => $repository_scripts;
    'output/ui'                   : value => $repository_ui;
    'output/workflows'            : value => $repository_output_workflow;
    'output/heat'                 : value => $repository_output_heat;
    'output/agent'                : value => $repository_output_agent;
    'output/scripts'              : value => $repository_output_scripts;
    'keystone/auth_host'          : value => $repository_auth_host;
    'keystone/auth_port'          : value => $repository_auth_port;
    'keystone/auth_protocol'      : value => $repository_auth_protocol;
    'keystone/admin_user'         : value => $repository_admin_user;
    'keystone/admin_password'     : value => $repository_admin_password;
    'keystone/admin_tenant_name'  : value => $repository_admin_tenant_name
  }

  Murano_repository_config<||> ~> Service['murano_repository']
  Package['murano_repository'] -> Murano_repository_config<||>
  Package['murano_repository'] -> Service['murano_repository']

}
