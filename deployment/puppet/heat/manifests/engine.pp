class heat::engine (
  $pacemaker         = false,
  $keystone_host     = '127.0.0.1',
  $keystone_port     = '35357',
  $keystone_protocol = 'http',
  $keystone_user     = 'heat',
  $keystone_tenant   = 'services',
  $keystone_password = 'password',
  $bind_host         = '0.0.0.0',
  $bind_port         = '8001',
  $verbose           = 'False',
  $debug             = 'False',
  $heat_stack_user_role          = 'heat_stack_user',
  $heat_metadata_server_url      = 'http://127.0.0.1:8000',
  $heat_waitcondition_server_url = 'http://127.0.0.1:8000/v1/waitcondition',
  $heat_watch_server_url         = 'http://127.0.0.1:8003',
  $rabbit_hosts                  = '',
  $rabbit_host                   = '',
  $rabbit_userid                 = '',
  $rabbit_ha_queues              = '',
  $rabbit_password               = '',
  $rabbit_virtualhost            = '/',
  $rabbit_port                   = '5672',
  $auth_encryption_key           = '%ENCRYPTION_KEY%',
  $db_backend                    = 'heat.db.sqlalchemy.api',
  $instance_connection_https_validate_certificates = '1',
  $instance_connection_is_secure = '0',
  $log_file                      = '/var/log/heat/engine.log',
  $rpc_backend                   = 'heat.openstack.common.rpc.impl_kombu',
  $use_stderr                    = 'False',
  $use_syslog                    = 'False',
  $ocf_scripts_dir               = '/usr/lib/ocf/resource.d',
  $ocf_scripts_provider          = 'mirantis',
) {

  include heat::params

  validate_string($keystone_password)
  $service_name = $::heat::params::engine_service_name
  $package_name = $::heat::params::engine_package_name

  package { 'heat-engine' :
    ensure => installed,
    name   => $package_name,
  }

  file { '/etc/heat/heat-engine.conf':
    owner   => 'heat',
    group   => 'heat',
    mode    => '0640',
  }

  if $rabbit_hosts {
    if is_array($rabbit_hosts) {
      $rabbit_hosts_v = join($rabbit_hosts, ',')
    } else {
      $rabbit_hosts_v = $rabbit_hosts
    }
    heat_engine_config { 'DEFAULT/rabbit_host':  ensure => absent }
    heat_engine_config { 'DEFAULT/rabbit_port':  ensure => absent }
    heat_engine_config { 'DEFAULT/rabbit_hosts': value => $rabbit_hosts_v }
  } else {
    heat_engine_config { 'DEFAULT/rabbit_host': value => $rabbit_host }
    heat_engine_config { 'DEFAULT/rabbit_port': value => $rabbit_port }
    heat_engine_config { 'DEFAULT/rabbit_hosts':
      value => "${rabbit_host}:${rabbit_port}"
    }
  }

  if size($rabbit_hosts) > 1 {
    heat_engine_config { 'DEFAULT/rabbit_ha_queues': value => true }
  } else {
    heat_engine_config { 'DEFAULT/rabbit_ha_queues': value => false }
  }

  if !$pacemaker {

    # standard service mode

	  service { 'heat-engine':
	    ensure     => 'running',
	    name       => $service_name,
	    enable     => true,
	    hasstatus  => true,
	    hasrestart => true,
	  }

	} else {

    # pacemaker resource mode

    file { 'heat-engine-ocf' :
      ensure  => present,
      path    => "${ocf_scripts_dir}/${ocf_scripts_provider}/${service_name}",
      mode    => '0755',
      owner   => 'root',
      group   => 'root',
      content => template('heat/heat_engine.ocf.erb')
    }

    service { 'heat-engine':
      ensure     => 'running',
      name       => $service_name,
      enable     => true,
      hasstatus  => true,
      hasrestart => true,
      provider   => 'pacemaker',
    }
    
    cs_shadow { $service_name :
      cib => $service_name,
    }

    cs_commit { $service_name :
      cib => $service_name,
    }
    
    corosync::cleanup { $service_name : }
    
    cs_resource { $service_name :
      ensure          => present,
      cib             => $service_name,
      primitive_class => 'ocf',
      provided_by     => $ocf_scripts_provider,
      primitive_type  => $service_name,  
    }
    
    File['heat-engine-ocf'] -> Cs_shadow[$service_name] -> Cs_resource[$service_name] -> Cs_commit[$service_name] ~> Corosync::Cleanup[$service_name] -> Service['heat-engine']

	}

  exec {'heat-encryption-key-replacement':
    command => 'sed -i "s/%ENCRYPTION_KEY%/`hexdump -n 16 -v -e \'/1 "%02x"\' /dev/random`/" /etc/heat/heat-engine.conf',
    path    => [ '/usr/bin', '/bin' ],
    onlyif  => 'grep -c ENCRYPTION_KEY /etc/heat/heat-engine.conf',
  }

  heat_engine_config {
    'DEFAULT/rabbit_userid'                                   : value => $rabbit_userid;
    'DEFAULT/rabbit_password'                                 : value => $rabbit_password;
    'DEFAULT/rabbit_virtualhost'                              : value => $rabbit_virtualhost;
    'DEFAULT/debug'                                           : value => $debug;
    'DEFAULT/verbose'                                         : value => $verbose;
    'DEFAULT/log_dir'                                         : value => $::heat::params::log_dir;
    'DEFAULT/bind_host'                                       : value => $bind_host;
    'DEFAULT/bind_port'                                       : value => $bind_port;
    'DEFAULT/heat_stack_user_role'                            : value => $heat_stack_user_role;
    'DEFAULT/heat_metadata_server_url'                        : value => $heat_metadata_server_url;
    'DEFAULT/heat_waitcondition_server_url'                   : value => $heat_waitcondition_server_url;
    'DEFAULT/heat_watch_server_url'                           : value => $heat_watch_server_url;
    'DEFAULT/auth_encryption_key'                             : value => $auth_encryption_key;
    'DEFAULT/db_backend'                                      : value => $db_backend;
    'DEFAULT/instance_connection_https_validate_certificates' : value => $instance_connection_https_validate_certificates;
    'DEFAULT/instance_connection_is_secure'                   : value => $instance_connection_is_secure;
    'DEFAULT/log_file'                                        : value => $log_file;
    'DEFAULT/rpc_backend'                                     : value => $rpc_backend;
    'DEFAULT/use_stderr'                                      : value => $use_stderr;
    'DEFAULT/use_syslog'                                      : value => $use_syslog;
  }

  Package['heat-common'] -> Package['heat-engine'] -> File['/etc/heat/heat-engine.conf'] -> Heat_engine_config<||> ~> Service['heat-engine']
  File['/etc/heat/heat-engine.conf'] -> Exec['heat-encryption-key-replacement'] -> Service['heat-engine']
  File['/etc/heat/heat-engine.conf'] ~> Service['heat-engine']
  Class['heat::db'] -> Service['heat-engine']
  Heat_engine_config<||> -> Exec['heat_db_sync'] -> Service['heat-engine']

}
