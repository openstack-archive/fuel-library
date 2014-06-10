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
    $repository_data_dir            = '/var/cache/murano',
    $repository_replication_port    = '8084',
    $repository_replication_nodes   = [],
    $firewall_rule_name             = '202 murano-repository',
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

  $logging_file = '/etc/murano/murano-repository-logging.conf'
  if $use_syslog and !$debug { #syslog and nondebug case
    murano_repository_config {
      'DEFAULT/log_config'         : value => $logging_file;
      'DEFAULT/use_syslog'          : value  => true;
      'DEFAULT/syslog_log_facility' : value  => $syslog_log_facility;
    }
    file {"murano-repository-logging.conf":
      content => template('murano/logging.conf.erb'),
      path    => $logging_file,
      require => Package['murano_repository'],
      notify  => Service['murano_repository'],
    }
  } else { #other syslog debug or nonsyslog debug/nondebug cases
    murano_repository_config {
      'DEFAULT/log_config': ensure => absent;
      'DEFAULT/log_file'            : value  => $log_file;
      'DEFAULT/use_syslog': value  => false;
    }
    }

  $ha_nodes = nodes_to_node_port_list($repository_replication_nodes, $repository_replication_port)

  if ($ha_nodes != '') {
    firewall { $firewall_rule_name :
      dport   => [ $repository_replication_port ],
      proto   => 'tcp',
      action  => 'accept',
    }
  }

  murano_repository_config {
    'DEFAULT/verbose'             : value => $verbose;
    'DEFAULT/debug'               : value => $debug;
    'DEFAULT/host'                : value => $repository_host;
    'DEFAULT/port'                : value => $repository_port;
    'DEFAULT/manifests'           : value => $repository_manifests;
    'DEFAULT/ui'                  : value => $repository_ui;
    'DEFAULT/workflows'           : value => $repository_workflows;
    'DEFAULT/heat'                : value => $repository_heat;
    'DEFAULT/agent'               : value => $repository_agent;
    'DEFAULT/scripts'             : value => $repository_scripts;
    'DEFAULT/data_dir'            : value => "${repository_data_dir}/muranorepository-cache";
    'DEFAULT/ha_nodes'            : value => $ha_nodes, ensure => $ha_nodes ? { '' => 'absent', default => 'present' };
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
}

