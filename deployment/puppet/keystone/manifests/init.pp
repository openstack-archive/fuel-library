#
# Module for managing keystone config.
#
# == Parameters
#
#   [package_ensure] Desired ensure state of packages. Optional. Defaults to present.
#     accepts latest or specific versions.
#   [bind_host] Host that keystone binds to.
#   [bind_port] Port that keystone binds to.
#   [public_port]
#   [compute_port]
#   [admin_port]
#   [admin_port] Port that can be used for admin tasks.
#   [admin_token] Admin token that can be used to authenticate as a keystone
#     admin. Required.
#   [verbose] Rather keystone should log at verbose level. Optional.
#     Defaults to False.
#   [debug] Rather keystone should log at debug level. Optional.
#     Defaults to False.
#   [use_syslog] Rather or not keystone should log to syslog. Optional.
#     Defaults to False.
#   [syslog_log_facility] Facility for syslog, if used. Optional. Note: duplicating conf option 
#     wouldn't have been used, but more powerfull rsyslog features managed via conf template instead
#   [syslog_log_level] logging level for non verbose and non debug mode. Optional.
#   [catalog_type] Type of catalog that keystone uses to store endpoints,services. Optional.
#     Defaults to sql. (Also accepts template)
#   [token_format] Format keystone uses for tokens. Optional. Defaults to UUID (PKI is grizzly native mode though).
#     Supports PKI and UUID.
#   [cache_dir] Directory created when token_format is PKI. Optional.
#     Defaults to /var/cache/keystone.
#   [enalbles] If the keystone services should be enabled. Optioal. Default to true.
#   [sql_conneciton] Url used to connect to database.
#   [idle_timeout] Timeout when db connections should be reaped.
#
# == Dependencies
#  None
#
# == Examples
#
#   class { 'keystone':
#     log_verbose => 'True',
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
  $package_ensure      = 'present',
  $bind_host           = '0.0.0.0',
  $public_port         = '5000',
  $admin_port          = '35357',
  $compute_port        = '3000',
  $verbose             = 'False',
  $debug               = 'False',
  $use_syslog          = false,
  $syslog_log_facility = 'LOCAL7',
  $syslog_log_level = 'WARNING',
  $catalog_type        = 'sql',
  $token_format        = 'UUID',
#  $token_format        = 'PKI',
  $cache_dir           = '/var/cache/keystone',
  $enabled             = true,
  $sql_connection      = 'sqlite:////var/lib/keystone/keystone.db',
  $idle_timeout        = '200'
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
    mode    => '0644',
    require => Package['keystone'],
  }

  if $use_syslog {
    keystone_config {
      'DEFAULT/log_config': value => "/etc/keystone/logging.conf";
      'DEFAULT/log_file': ensure=> absent;
      'DEFAULT/logdir': ensure=> absent;
    }
    file {"keystone-logging.conf":
      content => template('keystone/logging.conf.erb'),
      path => "/etc/keystone/logging.conf",
      require => File['/etc/keystone'],
      # We must notify service for new logging rules
      notify => Service['keystone'],
    }
    file { "keystone-all.log":
      path => "/var/log/keystone-all.log",
    }
    file { '/etc/rsyslog.d/20-keystone.conf':
      ensure => present,
      content => template('keystone/rsyslog.d.erb'),
    }

    # We must notify rsyslog to apply new logging rules
    include rsyslog::params
    File['/etc/rsyslog.d/20-keystone.conf'] ~> Service <| title == "$rsyslog::params::service_name" |>

  } else  {
    keystone_config {
     'DEFAULT/log_config': ensure => absent;
     'DEFAULT/log_file': value => $log_file;
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
    mode    => 0755,
    notify  => Service['keystone'],
  }

  case $::osfamily {
    'Debian' : {
      file { '/etc/keystone/keystone.conf':
        ensure  => present,
        owner   => 'keystone',
        group   => 'keystone',
        require => File['/etc/keystone'],
        notify  => Service['keystone'],
      }
      User['keystone'] -> File['/etc/keystone']
      Group['keystone'] -> File['/etc/keystone']
      Keystone_config <| |> -> Package['keystone']
      File['/etc/keystone/keystone.conf'] -> Keystone_config <| |>
    }
    'RedHat' : {
      Package['keystone'] -> User['keystone']
      Package['keystone'] -> Group['keystone']
      Package['keystone'] -> File['/etc/keystone']
      Package['keystone'] -> Keystone_config <| |>
    }
  }

  # default config
  keystone_config {
    'DEFAULT/admin_token':  value => $admin_token;
    'DEFAULT/bind_host':    value => $bind_host;
    'DEFAULT/public_port':  value => $public_port;
    'DEFAULT/admin_port':   value => $admin_port;
    'DEFAULT/compute_port': value => $compute_port;
    'DEFAULT/debug':        value => $debug;
    'DEFAULT/verbose':      value => $verbose;
    'DEFAULT/use_syslog':   value => $use_syslog;
    'identity/driver': value =>"keystone.identity.backends.sql.Identity";
    'token/driver': value =>"keystone.token.backends.sql.Token";
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

  # db connection config
  keystone_config {
    'sql/connection':   value => $sql_connection;
    'sql/idle_timeout': value => $idle_timeout;
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
  if $::osfamily == "Debian"
  {
    Keystone_config <| |> -> Package['keystone']
  }
  service { 'keystone':
    name       => $::keystone::params::service_name,
    ensure     => $service_ensure,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    require    => [Package['keystone']],
    provider   => $::keystone::params::service_provider,
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
      notify      => Service['keystone'],
      subscribe   => Package['keystone'],
    }
  }
}
