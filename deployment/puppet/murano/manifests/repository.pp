class murano::repository (
    $use_syslog                     = false,
    $syslog_log_facility            = 'LOG_LOCAL0',
    $log_file                       = '/var/log/murano/murano-repository.log',
    $verbose                        = false,
    $debug                          = false,
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
    $repository_cache_dir           = '/var/cache/murano',
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

  if $use_syslog and !$debug {
    murano_repository_config {
      'DEFAULT/use_syslog'          : value  => true;
      'DEFAULT/use_stderr'          : ensure => absent;
      'DEFAULT/syslog_log_facility' : value  => $syslog_log_facility;
      'DEFAULT/log_file'            : ensure => absent;
    }

    file { 'murano-repository-logging.conf':
      content => template('murano/logging.conf.erb'),
      path    => '/etc/murano/murano-repository-logging.conf',
    }
  }
  else {
    murano_repository_config {
      'DEFAULT/use_syslog'          : ensure => absent;
      'DEFAULT/use_stderr'          : ensure => absent;
      'DEFAULT/syslog_log_facility' : ensure => absent;
      'DEFAULT/log_file'            : value  => $log_file;
    }

    file { 'murano-repository-logging.conf':
      content => template('murano/logging.conf-nosyslog.erb'),
      path    => '/etc/murano/murano-repository-logging.conf',
    }
  }

  murano_repository_config {
    'DEFAULT/host'                : value => $repository_host;
    'DEFAULT/port'                : value => $repository_port;
    'DEFAULT/manifests'           : value => $repository_manifests;
    'DEFAULT/ui'                  : value => $repository_ui;
    'DEFAULT/workflows'           : value => $repository_workflows;
    'DEFAULT/heat'                : value => $repository_heat;
    'DEFAULT/agent'               : value => $repository_agent;
    'DEFAULT/scripts'             : value => $repository_scripts;
    'DEFAULT/cache_dir'           : value => "${repository_cache_dir}/muranorepository-cache";
    'DEFAULT/logging_context_format_string':
    value => 'murano-repository %(asctime)s.%(msecs)03d %(process)d %(levelname)s %(name)s [%(request_id)s %(user)s %(tenant)s] %(instance)s%(message)s';
    'DEFAULT/logging_default_format_string':
    value => 'murano-repository %(asctime)s %(levelname)s %(name)s [-] %(instance)s %(message)s';
    'output/ui'                   : value => $repository_ui;
    'output/workflows'            : value => $repository_output_workflows;
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
  File['murano-repository-logging.conf'] ~> Service['murano_repository']

}

