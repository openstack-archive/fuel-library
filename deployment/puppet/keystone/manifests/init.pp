#
# Module for managing keystone config.
#
# == Parameters
#
#   [package_ensure] Desired ensure state of packages. Optional. Defaults to present.
#     accepts installed or specific versions.
#   [bind_host] Host that keystone binds to.
#   [bind_port] Port that keystone binds to.
#   [public_port]
#   [compute_port]
#   [admin_port]
#   [admin_port] Port that can be used for admin tasks.
#   [admin_token] Admin token that can be used to authenticate as a keystone
#     admin. Required.
#   [verbose] Rather keystone should log at verbose level. Optional.
#     Defaults to false.
#   [debug] Rather keystone should log at debug level. Optional.
#     Defaults to false.
#   [use_syslog] Rather or not keystone should log to syslog. Optional.
#     Defaults to false.
#   [syslog_log_facility] Facility for syslog, if used. Optional.
#   [*log_dir*]
#     (optional) Directory where logs should be stored
#     If set to boolean false, it will not log to any directory
#     Defaults to '/var/log/keystone'
#   [catalog_type] Type of catalog that keystone uses to store endpoints,services. Optional.
#     Defaults to sql. (Also accepts template)
#   [token_format] Format keystone uses for tokens. Optional. Defaults to UUID (PKI is grizzly native mode though).
#     Supports PKI and UUID.
#   [cache_dir] Directory created when token_format is PKI. Optional.
#     Defaults to /var/cache/keystone.
#   [enalbles] If the keystone services should be enabled. Optioal. Default to true.
#   [sql_conneciton] Url used to connect to database.
#   [idle_timeout] Timeout when db connections should be reaped.
#   [notification_driver] RPC driver. Not enabled by default
#   [notification_topics] AMQP topics to publish to when using the RPC notification driver.
#   [control_exchange] AMQP exchange to connect to if using RabbitMQ or Qpid
#
# == Dependencies
#  None
#
# == Examples
#
#   class { 'keystone':
#     verbose => true,
#     admin_token => 'my_special_token',
#   }
#
# == Authors
#
#   Dan Bode dan@puppetlabs.com
#
# == Copyright
#
# Copyright 2012 Puppetlabs Inc, unless otherwise noted.
#
class keystone(
  $admin_token,
  $package_ensure       = 'present',
  $bind_host            = '0.0.0.0',
  $public_port          = '5000',
  $admin_port           = '35357',
  $compute_port         = '3000',
  $verbose              = false,
  $debug                = false,
  $use_syslog           = false,
  $syslog_log_facility  = 'LOG_LOCAL7',
  $log_dir              = '/var/log/keystone',
  $catalog_type         = 'sql',
  $token_format         = 'UUID',
  $cache_dir            = '/var/cache/keystone',
  $memcache_servers     = false,
  $memcache_server_port = false,
  $enabled              = true,
  $sql_connection       = 'sqlite:////var/lib/keystone/keystone.db',
  $idle_timeout         = '200',
  $rabbit_host          = 'localhost',
  $rabbit_hosts         = false,
  $rabbit_password = 'guest',
  $rabbit_port = '5672',
  $rabbit_userid = 'guest',
  $rabbit_virtual_host = '/',
  $rabbit_use_ssl = false,
  $notification_driver = false,
  $notification_topics = false,
  $control_exchange = false,
  $max_pool_size        = '10',
  $max_overflow         = '30',
  $max_retries          = '-1',
) {

  validate_re($catalog_type,   'template|sql')
  validate_re($token_format,  'UUID|PKI')

  Keystone_config<||> ~> Service['keystone']
  Keystone_config<||> ~> Exec<| title == 'keystone-manage db_sync'|>
  Package['keystone'] ~> Exec<| title == 'keystone-manage pki_setup'|> ~> Service['keystone']

  File {
    ensure  => present,
    owner   => 'keystone',
    group   => 'keystone',
    mode    => '0640',
    require => Package['keystone'],
  }

  # logging config
  if $log_dir {
    keystone_config {
      'DEFAULT/log_dir': value => $log_dir;
    }
  } else {
    keystone_config {
      'DEFAULT/log_dir': ensure => absent;
    }
  }

  include 'keystone::params'

  package { 'keystone':
    name   => $::keystone::params::package_name,
    ensure => $package_ensure,
  }

  group { 'keystone':
    ensure  => present,
    system  => true,
  }

  user { 'keystone':
    ensure  => 'present',
    gid     => 'keystone',
    system  => true,
  }

  file { ['/etc/keystone', '/var/log/keystone', '/var/lib/keystone']:
    ensure  => directory,
    owner   => 'keystone',
    group   => 'keystone',
    mode    => '0755',
    notify  => Service['keystone'],
  }
  if $::operatingsystem == 'Ubuntu' {
   if $service_provider == 'pacemaker' {
      file { '/etc/init/keystone.override':
        ensure  => present,
        content => "manual",
        mode    => '0644',
        replace => "no",
        owner   => 'root',
        group   => 'root',
      }

      File['/etc/init/keystone.override'] -> Package['keystone']

      exec { 'remove-keystone-bootblockr':
        command => 'rm -rf /etc/init/keystone.override',
        path    => ['/bin', '/usr/bin'],
        require => Package['keystone']
      }
    }
  }

      Package['keystone'] -> User['keystone']
      Package['keystone'] -> Group['keystone']
      Package['keystone'] -> File['/etc/keystone']
      Package['keystone'] -> Keystone_config <| |>

  # default config
  keystone_config {
    'DEFAULT/admin_token':  value => $admin_token;
    'DEFAULT/bind_host':    value => $bind_host;
    'DEFAULT/public_port':  value => $public_port;
    'DEFAULT/admin_port':   value => $admin_port;
    'DEFAULT/compute_port': value => $compute_port;
    'DEFAULT/debug':        value => $debug;
    'DEFAULT/verbose':      value => $verbose;
    'identity/driver': value =>"keystone.identity.backends.sql.Identity";
    'policy/driver': value =>"keystone.policy.backends.rules.Policy";
    'ec2/driver': value =>"keystone.contrib.ec2.backends.sql.Ec2";
    'filter:debug/paste.filter_factory': value =>"keystone.common.wsgi:Debug.factory";
    'filter:token_auth/paste.filter_factory': value =>"keystone.middleware:TokenAuthMiddleware.factory";
    'filter:admin_token_auth/paste.filter_factory': value =>"keystone.middleware:AdminTokenAuthMiddleware.factory";
    'filter:xml_body/paste.filter_factory': value =>"keystone.middleware:XmlBodyMiddleware.factory";
    'filter:json_body/paste.filter_factory': value =>"keystone.middleware:JsonBodyMiddleware.factory";
    'filter:user_crud_extension/paste.filter_factory': value =>"keystone.contrib.user_crud:CrudExtension.factory";
    'filter:crud_extension/paste.filter_factory': value =>"keystone.contrib.admin_crud:CrudExtension.factory";
    'filter:ec2_extension/paste.filter_factory': value =>"keystone.contrib.ec2:Ec2Extension.factory";
    'filter:s3_extension/paste.filter_factory': value =>"keystone.contrib.s3:S3Extension.factory";
    'filter:url_normalize/paste.filter_factory': value =>"keystone.middleware:NormalizingFilter.factory";
    'filter:stats_monitoring/paste.filter_factory': value =>"keystone.contrib.stats:StatsMiddleware.factory";
    'filter:stats_reporting/paste.filter_factory': value =>"keystone.contrib.stats:StatsExtension.factory";
    'app:public_service/paste.app_factory': value =>"keystone.service:public_app_factory";
    'app:admin_service/paste.app_factory': value =>"keystone.service:admin_app_factory";
    'pipeline:public_api/pipeline': value =>"stats_monitoring url_normalize token_auth admin_token_auth xml_body json_body debug ec2_extension user_crud_extension public_service";
    'pipeline:admin_api/pipeline': value =>"stats_monitoring url_normalize token_auth admin_token_auth xml_body json_body debug stats_reporting ec2_extension s3_extension crud_extension admin_service";
    'app:public_version_service/paste.app_factory': value =>"keystone.service:public_version_app_factory";
    'app:admin_version_service/paste.app_factory': value =>"keystone.service:admin_version_app_factory";
    'pipeline:public_version_api/pipeline': value =>"stats_monitoring url_normalize xml_body public_version_service";
    'pipeline:admin_version_api/pipeline': value =>"stats_monitoring url_normalize xml_body admin_version_service";
    'composite:main/use': value =>"egg:Paste#urlmap";
    'composite:main//v2.0': value =>"public_api";
    'composite:main//': value =>"public_version_api";
    'composite:admin/use': value =>"egg:Paste#urlmap";
    'composite:admin//v2.0': value =>"admin_api";
    'composite:admin//': value =>"admin_version_api";
  }

  if($sql_connection =~ /mysql:\/\/\S+:\S+@\S+\/\S+/) {
    require 'mysql::python'
  } elsif($sql_connection =~ /postgresql:\/\/\S+:\S+@\S+\/\S+/) {

  } elsif($sql_connection =~ /sqlite:\/\//) {

  } else {
    fail("Invalid db connection ${sql_connection}")
  }

  # memcache connection config
  if $memcache_servers {
    validate_array($memcache_servers)
    Service<| title == 'memcached' |> -> Service['keystone']
    keystone_config {
      'token/driver': value => 'keystone.token.backends.memcache.Token';
      'cache/enabled': value => 'true';
      'cache/backend': value => 'keystone.cache.memcache_pool';
      'memcache/servers': value => inline_template("<%= @memcache_servers.collect{|ip| ip + ':' + @memcache_server_port }.join ',' %>");
    }
    # work-arounding multi-line inifile limitations with file_line resource
    file_line { 'backend_argument_pool':
      line    => 'backend_argument=pool_maxsize:100',
      match   => '^\s*backend_argument\s*=\s*pool_maxsize:',
      path    => '/etc/keystone/keystone.conf',
      after   => '^\s*backend\s*=',
      require => Keystone_config['cache/backend'],
      notify  => Service['keystone'],
    }
    file_line { 'backend_argument_url':
      line    => inline_template("backend_argument=url:<%= @memcache_servers.collect{|ip| ip }.join ',' %>"),
      match   => '^\s*backend_argument\s*=\s*url:',
      path    => '/etc/keystone/keystone.conf',
      after   => '^\s*backend\s*=',
      require => Keystone_config['cache/backend'],
      notify  => Service['keystone'],
    }
  } else {
    keystone_config {
      'token/driver': value => 'keystone.token.backends.sql.Token';
      'memcache/servers': ensure => absent;
    }
  }

  # db connection config
  keystone_config {
    'database/connection':    value => $sql_connection;
    'database/idle_timeout':  value => $idle_timeout;
    'database/max_pool_size': value => $max_pool_size;
    'database/max_retries':   value => $max_retries;
    'database/max_overflow':  value => $max_overflow;
  }

  # configure based on the catalog backend
  if($catalog_type == 'template') {
    keystone_config {
      'catalog/driver':
        value => 'keystone.catalog.backends.templated.TemplatedCatalog';
      'catalog/template_file':
        value => '/etc/keystone/default_catalog.templates';
    }
  } elsif($catalog_type == 'sql' ) {
    keystone_config { 'catalog/driver':
      value => ' keystone.catalog.backends.sql.Catalog'
    }
  }

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }
  Keystone_config <| |> -> Service['keystone']
  service { 'keystone':
    name       => $::keystone::params::service_name,
    ensure     => $service_ensure,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    require    => [Package['keystone']],
    provider   => $::keystone::params::service_provider,
  }
  Package<| title == 'keystone'|> ~> Service<| title == 'keystone'|>
  if !defined(Service['keystone']) {
    notify{ "Module ${module_name} cannot notify service keystone on package update": }
  }

  keystone_config { 'signing/token_format': value => $token_format }
  if($token_format  == 'PKI') {
    file { $cache_dir:
      ensure => directory,
      notify  => Service['keystone'],
    }

    # keystone-manage pki_setup Should be run as the same system user that will be running the Keystone service to ensure
    # proper ownership for the private key file and the associated certificates
    exec { 'keystone-manage pki_setup':
      path        => '/usr/bin',
      user        => 'keystone',
      refreshonly => true,
    }
  }

  if $enabled {
    # this probably needs to happen more often than just when the db is
    # created
    exec { 'keystone-manage db_sync':
      user        => 'keystone',
      path        => '/usr/bin',
      refreshonly => true,
      tries       => 10,  # waiting if haproxy was restarted
      try_sleep   => 6,   # near at this exec
      notify      => Service['keystone'],
      subscribe   => Package['keystone'],
    }
  }

  if $notification_driver {
    keystone_config { 'DEFAULT/notification_driver': value => $notification_driver }
  } else {
    keystone_config { 'DEFAULT/notification_driver': ensure => absent }
  }
  if $notification_topics {
    keystone_config { 'DEFAULT/notification_topics': value => $notification_topics }
  } else {
    keystone_config { 'DEFAULT/notification_topics': ensure => absent }
  }
  if $control_exchange {
    keystone_config { 'DEFAULT/control_exchange': value => $control_exchange }
  } else {
    keystone_config { 'DEFAULT/control_exchange': ensure => absent }
  }

  keystone_config {
    'DEFAULT/rabbit_password': value => $rabbit_password;
    'DEFAULT/rabbit_userid': value => $rabbit_userid;
    'DEFAULT/rabbit_virtual_host': value => $rabbit_virtual_host;
  }

  if $rabbit_hosts {
    keystone_config { 'DEFAULT/rabbit_hosts': value => join($rabbit_hosts, ',') }
    keystone_config { 'DEFAULT/rabbit_ha_queues': value => true }
  } else {
    keystone_config { 'DEFAULT/rabbit_host': value => $rabbit_host }
    keystone_config { 'DEFAULT/rabbit_port': value => $rabbit_port }
    keystone_config { 'DEFAULT/rabbit_hosts': value => "${rabbit_host}:${rabbit_port}" }
    keystone_config { 'DEFAULT/rabbit_ha_queues': value => false }
  }


  # Syslog configuration
  if $use_syslog {
    keystone_config {
      'DEFAULT/use_syslog':            value => true;
      'DEFAULT/use_syslog_rfc_format': value => true;
      'DEFAULT/syslog_log_facility':   value => $syslog_log_facility;
    }
  } else {
    keystone_config {
      'DEFAULT/use_syslog':           value => false;
    }
  }
}
