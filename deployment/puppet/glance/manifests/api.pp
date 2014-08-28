# == Class glance::api
#
# Configure API service in glance
#
# == Parameters
#
# [*keystone_password*]
#   (required) Password used to authentication.
#
# [*verbose*]
#   (optional) Rather to log the glance api service at verbose level.
#   Default: false
#
# [*debug*]
#   (optional) Rather to log the glance api service at debug level.
#   Default: false
#
# [*bind_host*]
#   (optional) The address of the host to bind to.
#   Default: 0.0.0.0
#
# [*bind_port*]
#   (optional) The port the server should bind to.
#   Default: 9292
#
# [*backlog*]
#   (optional) Backlog requests when creating socket
#   Default: 4096
#
# [*workers*]
#   (optional) Number of Glance API worker processes to start
#   Default: $::processorcount
#
# [*log_file*]
#   (optional) The path of file used for logging
#   If set to boolean false, it will not log to any file.
#   Default: /var/log/glance/api.log
#
#  [*log_dir*]
#    (optional) directory to which glance logs are sent.
#    If set to boolean false, it will not log to any directory.
#    Defaults to '/var/log/glance'
#
# [*registry_host*]
#   (optional) The address used to connect to the registry service.
#   Default: 0.0.0.0
#
# [*registry_port*]
#   (optional) The port of the Glance registry service.
#   Default: 9191
#
# [*auth_type*]
#   (optional) Type is authorization being used.
#   Defaults to 'keystone'
#
# [* auth_host*]
#   (optional) Host running auth service.
#   Defaults to '127.0.0.1'.
#
# [*auth_url*]
#   (optional) Authentication URL.
#   Defaults to 'http://localhost:5000/v2.0'.
#
# [* auth_port*]
#   (optional) Port to use for auth service on auth_host.
#   Defaults to '35357'.
#
# [* auth_uri*]
#   (optional) Complete public Identity API endpoint.
#   Defaults to false.
#
# [*auth_admin_prefix*]
#   (optional) Path part of the auth url.
#   This allow admin auth URIs like http://auth_host:35357/keystone/admin.
#   (where '/keystone/admin' is auth_admin_prefix)
#   Defaults to false for empty. If defined, should be a string with a leading '/' and no trailing '/'.
#
# [* auth_protocol*]
#   (optional) Protocol to use for auth.
#   Defaults to 'http'.
#
# [*pipeline*]
#   (optional) Partial name of a pipeline in your paste configuration file with the
#   service name removed.
#   Defaults to 'keystone+cachemanagement'.
#
# [*keystone_tenant*]
#   (optional) Tenant to authenticate to.
#   Defaults to services.
#
# [*keystone_user*]
#   (optional) User to authenticate as with keystone.
#   Defaults to 'glance'.
#
# [*enabled*]
#   (optional) Whether to enable services.
#   Defaults to true.
#
# [*sql_idle_timeout*]
#   (optional) Period in seconds after which SQLAlchemy should reestablish its connection
#   to the database.
#   Defaults to '3600'.
#
# [*sql_connection*]
#   (optional) Database connection.
#   Defaults to 'sqlite:///var/lib/glance/glance.sqlite'.
#
# [*use_syslog*]
#   (optional) Use syslog for logging.
#   Defaults to false.
#
# [*log_facility*]
#   (optional) Syslog facility to receive log lines.
#   Defaults to 'LOG_USER'.
#
# [*show_image_direct_url*]
#   (optional) Expose image location to trusted clients.
#   Defaults to false.
#
# [*purge_config*]
#   (optional) Whether to set only the specified config options
#   in the api config.
#   Defaults to false.
#
# [*cert_file*]
#   (optinal) Certificate file to use when starting API server securely
#   Defaults to false, not set
#
# [*key_file*]
#   (optional) Private key file to use when starting API server securely
#   Defaults to false, not set
#
# [*ca_file*]
#   (optional) CA certificate file to use to verify connecting clients
#   Defaults to false, not set
#
# [*mysql_module*]
#   (optional) Mysql puppet module version to use
#   Tested versions include 0.9 and 2.2
#   Defaults to '0.9'.
#
# [*known_stores*]
#   (optional)List of which store classes and store class locations are
#    currently known to glance at startup.
#    Defaults to false.
#    Example: ['glance.store.filesystem.Store','glance.store.http.Store']
#
class glance::api(
  $keystone_password,
  $verbose               = false,
  $debug                 = false,
  $bind_host             = '0.0.0.0',
  $bind_port             = '9292',
  $backlog               = '4096',
  $workers               = $::processorcount,
  $log_file              = '/var/log/glance/api.log',
  $log_dir               = '/var/log/glance',
  $registry_host         = '0.0.0.0',
  $registry_port         = '9191',
  $auth_type             = 'keystone',
  $auth_host             = '127.0.0.1',
  $auth_url              = 'http://localhost:5000/v2.0',
  $auth_port             = '35357',
  $auth_uri              = false,
  $auth_admin_prefix     = false,
  $auth_protocol         = 'http',
  $pipeline              = 'keystone+cachemanagement',
  $keystone_tenant       = 'services',
  $keystone_user         = 'glance',
  $enabled               = true,
  $sql_idle_timeout      = '3600',
  $sql_connection        = 'sqlite:///var/lib/glance/glance.sqlite',
  $use_syslog            = false,
  $log_facility          = 'LOG_USER',
  $show_image_direct_url = false,
  $purge_config          = false,
  $cert_file             = false,
  $key_file              = false,
  $ca_file               = false,
  $mysql_module          = '0.9',
  $known_stores          = false,
) inherits glance {

  require keystone::python

  validate_re($sql_connection, '(sqlite|mysql|postgresql):\/\/(\S+:\S+@\S+\/\S+)?')

  if ( $glance::params::api_package_name != $glance::params::registry_package_name ) {
    ensure_packages([$glance::params::api_package_name])
  }

  Package[$glance::params::api_package_name] -> File['/etc/glance/']
  Package[$glance::params::api_package_name] -> Glance_api_config<||>
  Package[$glance::params::api_package_name] -> Glance_cache_config<||>
  Package[$glance::params::api_package_name] ~> Service['glance-api']

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
    if ($mysql_module >= 2.2) {
      require 'mysql::bindings'
      require 'mysql::bindings::python'
    } else {
      require 'mysql::python'
    }
  } elsif($sql_connection =~ /postgresql:\/\/\S+:\S+@\S+\/\S+/) {

  } elsif($sql_connection =~ /sqlite:\/\//) {

  } else {
    fail("Invalid db connection ${sql_connection}")
  }

  # basic service config
  glance_api_config {
    'DEFAULT/verbose':               value => $verbose;
    'DEFAULT/debug':                 value => $debug;
    'DEFAULT/bind_host':             value => $bind_host;
    'DEFAULT/bind_port':             value => $bind_port;
    'DEFAULT/backlog':               value => $backlog;
    'DEFAULT/workers':               value => $workers;
    'DEFAULT/show_image_direct_url': value => $show_image_direct_url;
  }

  # known_stores config
  if $known_stores {
    glance_api_config {
      'DEFAULT/known_stores':  value => join($known_stores, ',');
    }
  } else {
    glance_api_config {
      'DEFAULT/known_stores': ensure => absent;
    }
  }

  glance_cache_config {
    'DEFAULT/verbose':   value => $verbose;
    'DEFAULT/debug':     value => $debug;
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
  # I do not believe this was required in Essex.
  # Does the API server now need to connect to the DB?
  # TODO figure out if I need this...
  glance_api_config {
    'DEFAULT/sql_connection':   value => $sql_connection;
    'DEFAULT/sql_idle_timeout': value => $sql_idle_timeout;
  }

  if $auth_uri {
    glance_api_config { 'keystone_authtoken/auth_uri': value => $auth_uri; }
  } else {
    glance_api_config { 'keystone_authtoken/auth_uri': value => "${auth_protocol}://${auth_host}:5000/"; }
  }

  # auth config
  glance_api_config {
    'keystone_authtoken/auth_host':     value => $auth_host;
    'keystone_authtoken/auth_port':     value => $auth_port;
    'keystone_authtoken/auth_protocol': value => $auth_protocol;
  }

  if $auth_admin_prefix {
    validate_re($auth_admin_prefix, '^(/.+[^/])?$')
    glance_api_config {
      'keystone_authtoken/auth_admin_prefix': value => $auth_admin_prefix;
    }
  } else {
    glance_api_config {
      'keystone_authtoken/auth_admin_prefix': ensure => absent;
    }
  }

  # Set the pipeline, it is allowed to be blank
  if $pipeline != '' {
    validate_re($pipeline, '^(\w+([+]\w+)*)*$')
    glance_api_config {
      'paste_deploy/flavor':
        ensure => present,
        value  => $pipeline,
    }
  } else {
    glance_api_config { 'paste_deploy/flavor': ensure => absent }
  }

  # keystone config
  if $auth_type == 'keystone' {
    glance_api_config {
      'keystone_authtoken/admin_tenant_name': value => $keystone_tenant;
      'keystone_authtoken/admin_user'       : value => $keystone_user;
      'keystone_authtoken/admin_password'   : value => $keystone_password;
    }
    glance_cache_config {
      'DEFAULT/auth_url'         : value => $auth_url;
      'DEFAULT/admin_tenant_name': value => $keystone_tenant;
      'DEFAULT/admin_user'       : value => $keystone_user;
      'DEFAULT/admin_password'   : value => $keystone_password;
    }
  }

  # SSL Options
  if $cert_file {
    glance_api_config {
      'DEFAULT/cert_file' : value => $cert_file;
    }
  } else {
    glance_api_config {
      'DEFAULT/cert_file': ensure => absent;
    }
  }
  if $key_file {
    glance_api_config {
      'DEFAULT/key_file'  : value => $key_file;
    }
  } else {
    glance_api_config {
      'DEFAULT/key_file': ensure => absent;
    }
  }
  if $ca_file {
    glance_api_config {
      'DEFAULT/ca_file'   : value => $ca_file;
    }
  } else {
    glance_api_config {
      'DEFAULT/ca_file': ensure => absent;
    }
  }

  # Logging
  if $log_file {
    glance_api_config {
      'DEFAULT/log_file': value  => $log_file;
    }
  } else {
    glance_api_config {
      'DEFAULT/log_file': ensure => absent;
    }
  }

  if $log_dir {
    glance_api_config {
      'DEFAULT/log_dir': value  => $log_dir;
    }
  } else {
    glance_api_config {
      'DEFAULT/log_dir': ensure => absent;
    }
  }

  # Syslog
  if $use_syslog {
    glance_api_config {
      'DEFAULT/use_syslog'          : value => true;
      'DEFAULT/syslog_log_facility' : value => $log_facility;
    }
  } else {
    glance_api_config {
      'DEFAULT/use_syslog': value => false;
    }
  }

  resources { 'glance_api_config':
    purge => $purge_config,
  }

  file { ['/etc/glance/glance-api.conf',
          '/etc/glance/glance-api-paste.ini',
          '/etc/glance/glance-cache.conf']:
  }

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  service { 'glance-api':
    ensure     => $service_ensure,
    name       => $::glance::params::api_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
  }
}
