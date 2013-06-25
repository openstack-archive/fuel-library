
#
# == Paremeters:
#
#  $verbose - rather to log the glance api service at verbose level.
#  Optional. Default: false
#
#  $debug - rather to log the glance api service at debug level.
#  Optional. Default: false
#
#  $default_store - Backend used to store glance dist images.
#  Optional. Default: file
#
#  $bind_host - The address of the host to bind to.
#  Optional. Default: 0.0.0.0
#
#  $bind_port - The port the server should bind to.
#  Optional. Default: 9292
#
#  $registry_host - The address used to connecto to the registy service.
#  Optional. Default:
#
#  $registry_port - The port of the Glance registry service.
#  Optional. Default: 9191
#
#  $log_file - The path of file used for logging
#  Optional. Default: /var/log/glance/api.log
#
# $use_syslog - Rather or not service should log to syslog. Optional.
#
class glance::api(
  $keystone_password,
  $verbose           = 'False',
  $debug             = 'False',
  $bind_host         = '0.0.0.0',
  $bind_port         = '9292',
  $backlog           = '4096',
  $workers           = $::processorcount,
  $log_file          = '/var/log/glance/api.log',
  $registry_host     = '0.0.0.0',
  $registry_port     = '9191',
  $auth_type         = 'keystone',
  $auth_host         = '127.0.0.1',
  $auth_port         = '35357',
  $auth_protocol     = 'http',
  $auth_url          = "http://127.0.0.1:5000/",
  $keystone_tenant   = 'admin',
  $keystone_user     = 'admin',
  $enabled           = true,
  $sql_idle_timeout  = '3600',
  $sql_connection    = 'sqlite:///var/lib/glance/glance.sqlite',
  $use_syslog = false
) inherits glance {

  # used to configure concat
  require 'keystone::python'

  validate_re($sql_connection, '(sqlite|mysql|posgres):\/\/(\S+:\S+@\S+\/\S+)?')
  $auth_uri = "http://$auth_host:$auth_port"
  Package['glance'] -> Glance_api_config<||>
  Package['glance'] -> Glance_cache_config<||>
  # adding all of this stuff b/c it devstack says glance-api uses the
  # db now
  Glance_api_config<||>   ~> Exec<| title == 'glance-manage db_sync' |>
  Glance_cache_config<||> ~> Exec<| title == 'glance-manage db_sync' |>
  Exec<| title == 'glance-manage db_sync' |> ~> Service['glance-api']
  Glance_api_config<||>   ~> Service['glance-api']
  Glance_cache_config<||> ~> Service['glance-api']

  File {
    ensure  => present,
    owner   => 'glance',
    group   => 'glance',
    mode    => '0640',
    notify  => Service['glance-api'],
    require => Class['glance'],
  }

  if($sql_connection =~ /mysql:\/\/\S+:\S+@\S+\/\S+/) {
    require 'mysql::python'
  } elsif($sql_connection =~ /postgresql:\/\/\S+:\S+@\S+\/\S+/) {

  } elsif($sql_connection =~ /sqlite:\/\//) {

  } else {
    fail("Invalid db connection ${sql_connection}")
  }
  
if $use_syslog
  {
 glance_api_config {'DEFAULT/log_config': value => "/etc/glance/logging.conf";}

}
else
{

 glance_api_config {'DEFAULT/log_config': ensure => absent;}
}

  # basic service config
  glance_api_config {
    'DEFAULT/verbose':   value => $verbose;
    'DEFAULT/debug':     value => $debug;
    'DEFAULT/bind_host': value => $bind_host;
    'DEFAULT/bind_port': value => $bind_port;
    'DEFAULT/backlog':   value => $backlog;
    'DEFAULT/workers':   value => $workers;
    'DEFAULT/log_file':  value => $log_file;
    'DEFAULT/use_syslog':  value => $use_syslog;
    'DEFAULT/registry_client_protocol':  value => "http";
    'DEFAULT/delayed_delete': value => "False";
    'DEFAULT/scrub_time': value => "43200";
    'DEFAULT/scrubber_datadir': value => "/var/lib/glance/scrubber";
    'DEFAULT/image_cache_dir': value => "/var/lib/glance/image-cache/";
  }

  glance_cache_config {
    'DEFAULT/verbose':   value => $verbose;
    'DEFAULT/debug':     value => $debug;
    'DEFAULT/use_syslog':  value => $use_syslog;
    'DEFAULT/image_cache_dir': value => "/var/lib/glance/image-cache/";
    'DEFAULT/log_file':  value => "/var/log/glance/image-cache.log";
    'DEFAULT/image_cache_stall_time':  value => "86400";
    'DEFAULT/image_cache_invalid_entry_grace_period':  value => "3600";
    'DEFAULT/image_cache_max_size':  value => "10737418240";
    'DEFAULT/filesystem_store_datadir':  value => "/var/lib/glance/images/";
  }

  # configure api service to connect registry service
  glance_api_config {
    'DEFAULT/registry_host': value => $registry_host;
    'DEFAULT/registry_port': value => $registry_port;
  }

  glance_cache_config {
    'DEFAULT/registry_host': value => $registry_host;
    'DEFAULT/registry_port': value => $registry_port;
  }

  # db connection config
  # I do not believe this was required in Essex. Does the API server now need to connect to the DB?
  # TODO figure out if I need this...
  glance_api_config {
    'DEFAULT/sql_connection':   value => $sql_connection;
    'DEFAULT/sql_idle_timeout': value => $sql_idle_timeout;
  }

  # auth config
  glance_api_config {
    'keystone_authtoken/auth_host':         value => $auth_host;
    'keystone_authtoken/auth_port':         value => $auth_port;
    'keystone_authtoken/auth_protocol':          value => $auth_protocol;
    'keystone_authtoken/auth_uri':          value => $auth_uri;
  }

  # keystone config
  if $auth_type == 'keystone' {
    glance_api_config {
      'paste_deploy/flavor':                  value => 'keystone+cachemanagement';
      'keystone_authtoken/admin_tenant_name': value => $keystone_tenant;
      'keystone_authtoken/admin_user':        value => $keystone_user;
      'keystone_authtoken/admin_password':    value => $keystone_password;
      'keystone_authtoken/signing_dir':       value => '/tmp/keystone-signing-glance';
      'keystone_authtoken/signing_dirname':   value => '/tmp/keystone-signing-glance';
    }
    glance_cache_config {
      'DEFAULT/auth_url':          value => $auth_uri;
      'DEFAULT/admin_tenant_name': value => $keystone_tenant;
      'DEFAULT/admin_user':        value => $keystone_user;
      'DEFAULT/admin_password':    value => $keystone_password;
    }
  }

  file { ['/etc/glance/glance-api.conf',
          '/etc/glance/glance-cache.conf'
         ]:
  }

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  Glance_api_config<| |> -> Service['glance-api']
  if $::osfamily == "Debian"
  {
  package{ 'glance-api':
    name => $::glance::params::api_package_name,
    ensure => $package_ensure,
   }
   File['/etc/glance/glance-api.conf']->Glance_api_config<| |>
   Glance_api_config<| |> -> Package['glance-api']
   File['/etc/glance/glance-cache.conf']->Glance_cache_config<| |>
   Glance_cache_config<| |> -> Package['glance-api']
   Package['glance-api'] -> Service['glance-api']
  }
  service { 'glance-api':
    name       => $::glance::params::api_service_name,
    ensure     => $service_ensure,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
  }
}
