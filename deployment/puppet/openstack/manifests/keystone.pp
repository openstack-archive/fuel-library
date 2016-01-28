#
# == Class: openstack::keystone
#
# Installs and configures Keystone
#
# === Parameters
#
# [db_host] Host where DB resides. Required.
# [keystone_db_password] Password for keystone DB. Required.
# [keystone_admin_token]. Auth token for keystone admin. Required.
# [public_address] Public address where keystone can be accessed. Required.
# [db_type] Type of DB used. Currently only supports mysql. Optional. Defaults to  'mysql'
# [keystone_db_user] Name of keystone db user. Optional. Defaults to  'keystone'
# [keystone_db_dbname] Name of keystone DB. Optional. Defaults to  'keystone'
# [verbose] Rather to print more verbose (INFO+) output. Optional. Defaults to false.
# [debug] Rather to print even more verbose (DEBUG+) output. If true, would ignore verbose option.
#     Optional. Defaults to false.
# [public_bind_host] Address that keystone binds to. Optional. Defaults to  '0.0.0.0'
# [admin_bind_host] Address that keystone binds to. Optional. Defaults to  '0.0.0.0'
# [internal_address] Internal address for keystone. Optional. Defaults to  $public_address
# [admin_address] Keystone admin address. Optional. Defaults to  $internal_address
# [enabled] If the service is active (true) or passive (false).
#   Optional. Defaults to  true
# [use_syslog] Rather or not service should log to syslog. Optional. Default to false.
# [use_stderr] Rather or not service should send output to stderr. Optional. Defaults to true.
# [syslog_log_facility] Facility for syslog, if used. Optional. Note: duplicating conf option
#        wouldn't have been used, but more powerfull rsyslog features managed via conf template instead
# [max_pool_size] SQLAlchemy backend related. Default 10.
# [max_overflow] SQLAlchemy backend related.  Default 30.
# [max_retries] SQLAlchemy backend related. Default -1.
#
# === Example
#
# class { 'openstack::keystone':
#   db_host               => '127.0.0.1',
#   keystone_db_password  => 'changeme',
#   admin_password        => 'changeme',
#   public_address        => '192.168.1.1',
#  }

class openstack::keystone (
  $public_url,
  $admin_url,
  $internal_url,
  $db_host,
  $db_password,
  $admin_token,
  $public_address,
  $public_ssl                  = false,
  $public_hostname             = false,
  $db_type                     = 'mysql',
  $db_user                     = 'keystone',
  $db_name                     = 'keystone',
  $verbose                     = false,
  $debug                       = false,
  $default_log_levels          = undef,
  $public_bind_host            = '0.0.0.0',
  $admin_bind_host             = '0.0.0.0',
  $internal_address            = false,
  $admin_address               = false,
  $memcache_servers            = false,
  $memcache_server_port        = false,
  $memcache_pool_maxsize       = false,
  $primary_controller          = false,
  $enabled                     = true,
  $package_ensure              = present,
  $use_syslog                  = false,
  $use_stderr                  = true,
  $syslog_log_facility         = 'LOG_LOCAL7',
  $region                      = 'RegionOne',
  $database_idle_timeout       = '200',
  $rabbit_hosts                = false,
  $rabbit_password             = 'guest',
  $rabbit_userid               = 'guest',
  $rabbit_virtual_host         = '/',
  $max_pool_size               = '10',
  $max_overflow                = '30',
  $max_retries                 = '-1',
  $token_caching               = false,
  $cache_backend               = 'keystone.cache.memcache_pool',
  $token_provider              = undef,
  $revoke_driver               = false,
  $ceilometer                  = false,
  $service_workers             = $::processorcount,
  $fernet_src_repository       = undef,
  $fernet_key_repository       = '/etc/keystone/fernet-keys',
) {

  # Install and configure Keystone
  if $db_type == 'mysql' {
    $database_connection = "mysql://${$db_user}:${db_password}@${db_host}/${db_name}?read_timeout=60"
  } else {
    fail("db_type ${db_type} is not supported")
  }

  # I have to do all of this crazy munging b/c parameters are not
  # set procedurally in Pupet
  if $internal_address {
    $internal_real = $internal_address
  } else {
    $internal_real = $public_address
  }
  if $admin_address {
    $admin_real = $admin_address
  } else {
    $admin_real = $internal_real
  }

  if $ceilometer {
    $notification_driver = 'messagingv2'
    $notification_topics = 'notifications'
  } else {
    $notification_driver = false
    $notification_topics = false
  }

  if $memcache_servers {
    $memcache_servers_real = suffix($memcache_servers, inline_template(':<%= @memcache_server_port %>'))
    $token_driver = 'keystone.token.persistence.backends.memcache_pool.Token'
  } else {
    $memcache_servers_real = false
    $token_driver = 'keystone.token.backends.sql.Token'
  }

  $public_endpoint = false

  #### Fernet Token ####
  if $token_provider == 'keystone.token.providers.fernet.Provider' {
    file { "$fernet_key_repository":
      source  => $fernet_src_repository,
      mode    => '0600',
      owner   => 'keystone',
      group   => 'keystone',
      recurse => true,
      require => Class['::keystone'],
      notify  => Service[httpd],
    }
  }

  if $enabled {
    class { '::keystone':
      verbose                      => $verbose,
      debug                        => $debug,
      catalog_type                 => 'sql',
      admin_token                  => $admin_token,
      enabled                      => false,
      database_connection          => $database_connection,
      public_bind_host             => $public_bind_host,
      admin_bind_host              => $admin_bind_host,
      admin_workers                => $service_workers,
      public_workers               => $service_workers,
      package_ensure               => $package_ensure,
      use_syslog                   => $use_syslog,
      use_stderr                   => $use_stderr,
      database_idle_timeout        => $database_idle_timeout,
      sync_db                      => $primary_controller,
      rabbit_password              => $rabbit_password,
      rabbit_userid                => $rabbit_userid,
      rabbit_hosts                 => $rabbit_hosts,
      rabbit_virtual_host          => $rabbit_virtual_host,
      memcache_servers             => $memcache_servers_real,
      token_driver                 => $token_driver,
      token_provider               => $token_provider,
      notification_driver          => $notification_driver,
      notification_topics          => $notification_topics,
      token_caching                => $token_caching,
      cache_backend                => $cache_backend,
      revoke_driver                => $revoke_driver,
      public_endpoint              => $public_endpoint,
      admin_endpoint               => $admin_url,
      memcache_dead_retry          => '60',
      memcache_socket_timeout      => '1',
      memcache_pool_maxsize        =>'1000',
      memcache_pool_unused_timeout => '60',
    }

    # TODO(aschultz): Remove when LP#1523393 has been addressed in upstream
    # keystone module. Should switch this to cache_memache_servers param on
    # the keystone class.
    keystone_config {
      'cache/memcache_servers': value => join(any2array($memcache_servers_real), ',');
    }

    # TODO (iberezovskiy): Move to globals (as it is done for sahara)
    # after new sync with upstream because of
    # https://github.com/openstack/puppet-keystone/blob/master/manifests/init.pp#L564
    class { '::keystone::logging':
      default_log_levels => $default_log_levels,
    }

    Package<| title == 'keystone'|> ~> Service<| title == 'keystone'|>
    if !defined(Service['keystone']) {
      notify{ "Module ${module_name} cannot notify service keystone on package update": }
    }

    if $use_syslog {
      keystone_config {
        'DEFAULT/use_syslog_rfc_format':  value  => true;
      }
    }

    # FIXME(mattymo): After LP#1528258 is closed, this can be removed. It will
    # become a default option.
    keystone_config {
      'DEFAULT/secure_proxy_ssl_header': value => 'HTTP_X_FORWARDED_PROTO';
    }

    keystone_config {
      'DATABASE/max_pool_size':                          value => $max_pool_size;
      'DATABASE/max_retries':                            value => $max_retries;
      'DATABASE/max_overflow':                           value => $max_overflow;
      'identity/driver':                                 value =>'keystone.identity.backends.sql.Identity';
      'policy/driver':                                   value =>'keystone.policy.backends.sql.Policy';
      'ec2/driver':                                      value =>'keystone.contrib.ec2.backends.sql.Ec2';
      'filter:debug/paste.filter_factory':               value =>'keystone.common.wsgi:Debug.factory';
      'filter:token_auth/paste.filter_factory':          value =>'keystone.middleware:TokenAuthMiddleware.factory';
      'filter:admin_token_auth/paste.filter_factory':    value =>'keystone.middleware:AdminTokenAuthMiddleware.factory';
      'filter:xml_body/paste.filter_factory':            value =>'keystone.middleware:XmlBodyMiddleware.factory';
      'filter:json_body/paste.filter_factory':           value =>'keystone.middleware:JsonBodyMiddleware.factory';
      'filter:user_crud_extension/paste.filter_factory': value =>'keystone.contrib.user_crud:CrudExtension.factory';
      'filter:crud_extension/paste.filter_factory':      value =>'keystone.contrib.admin_crud:CrudExtension.factory';
      'filter:ec2_extension/paste.filter_factory':       value =>'keystone.contrib.ec2:Ec2Extension.factory';
      'filter:s3_extension/paste.filter_factory':        value =>'keystone.contrib.s3:S3Extension.factory';
      'filter:url_normalize/paste.filter_factory':       value =>'keystone.middleware:NormalizingFilter.factory';
      'filter:stats_monitoring/paste.filter_factory':    value =>'keystone.contrib.stats:StatsMiddleware.factory';
      'filter:stats_reporting/paste.filter_factory':     value =>'keystone.contrib.stats:StatsExtension.factory';
      'app:public_service/paste.app_factory':            value =>'keystone.service:public_app_factory';
      'app:admin_service/paste.app_factory':             value =>'keystone.service:admin_app_factory';
      'pipeline:public_api/pipeline':                    value =>'stats_monitoring url_normalize token_auth admin_token_auth xml_body json_body debug ec2_extension user_crud_extension public_service';
      'pipeline:admin_api/pipeline':                     value =>'stats_monitoring url_normalize token_auth admin_token_auth xml_body json_body debug stats_reporting ec2_extension s3_extension crud_extension admin_service';
      'app:public_version_service/paste.app_factory':    value =>'keystone.service:public_version_app_factory';
      'app:admin_version_service/paste.app_factory':     value =>'keystone.service:admin_version_app_factory';
      'pipeline:public_version_api/pipeline':            value =>'stats_monitoring url_normalize xml_body public_version_service';
      'pipeline:admin_version_api/pipeline':             value =>'stats_monitoring url_normalize xml_body admin_version_service';
      'composite:main/use':                              value =>'egg:Paste#urlmap';
      'composite:main//v2.0':                            value =>'public_api';
      'composite:main//':                                value =>'public_version_api';
      'composite:admin/use':                             value =>'egg:Paste#urlmap';
      'composite:admin//v2.0':                           value =>'admin_api';
      'composite:admin//':                               value =>'admin_version_api';
    }

    class { 'keystone::endpoint':
      public_url   => $public_url,
      admin_url    => $admin_url,
      internal_url => $internal_url,
      region       => $region,
    }

    Exec <| title == 'keystone-manage db_sync' |> -> Class['keystone::endpoint']
    Haproxy_backend_status<||> -> Class['keystone::endpoint']
  }
}
