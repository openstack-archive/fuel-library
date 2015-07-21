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
#    Optional. Defaults to false.
# [public_bind_host] Address that keystone binds to. Optional. Defaults to  '0.0.0.0'
# [admin_bind_host] Address that keystone binds to. Optional. Defaults to  '0.0.0.0'
# [internal_address] Internal address for keystone. Optional. Defaults to  $public_address
# [admin_address] Keystone admin address. Optional. Defaults to  $internal_address
# [enabled] If the service is active (true) or passive (false).
#   Optional. Defaults to  true
# [use_syslog] Rather or not service should log to syslog. Optional. Default to false.
# [syslog_log_facility] Facility for syslog, if used. Optional. Note: duplicating conf option
#       wouldn't have been used, but more powerfull rsyslog features managed via conf template instead
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
  $public_bind_host            = '0.0.0.0',
  $admin_bind_host             = '0.0.0.0',
  $internal_address            = false,
  $admin_address               = false,
  $memcache_servers            = false,
  $memcache_server_port        = false,
  $memcache_pool_maxsize       = false,
  $enabled                     = true,
  $package_ensure              = present,
  $use_syslog                  = false,
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
  $revoke_driver               = false,
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
    $notification_driver = 'messaging'
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

  if $public_ssl {
    $public_endpoint = $public_hostname ? {
      false => false,
      default => "https://${public_hostname}:5000",
    }
  }

  if $enabled {
    class { '::keystone':
      verbose               => $verbose,
      debug                 => $debug,
      catalog_type          => 'sql',
      admin_token           => $admin_token,
      enabled               => $enabled,
      database_connection   => $database_connection,
      public_bind_host      => $public_bind_host,
      admin_bind_host       => $admin_bind_host,
      package_ensure        => $package_ensure,
      use_syslog            => $use_syslog,
      database_idle_timeout => $database_idle_timeout,
      rabbit_password       => $rabbit_password,
      rabbit_userid         => $rabbit_userid,
      rabbit_hosts          => $rabbit_hosts,
      rabbit_virtual_host   => $rabbit_virtual_host,
      memcache_servers      => $memcache_servers_real,
      token_driver          => $token_driver,
      token_provider        => 'keystone.token.providers.uuid.Provider',
      notification_driver   => $notification_driver,
      notification_topics   => $notification_topics,
      token_caching         => $token_caching,
      cache_backend         => $cache_backend,
      revoke_driver         => $revoke_driver,
    }

    if $memcache_servers {
      Service<| title == 'memcached' |> -> Service<| title == 'keystone'|>
      keystone_config {
        'cache/memcache_servers':             value => join($memcache_servers_real, ',');
        'cache/memcache_dead_retry':          value => '300';
        'cache/memcache_socket_timeout':      value => '1';
        'cache/memcache_pool_maxsize':        value => '1000';
        'cache/memcache_pool_unused_timeout': value => '60';
        'memcache/dead_retry':                value => '300';
        'memcache/socket_timeout':            value => '1';
      }
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

    keystone_config {
      'memcache/pool_maxsize':                           value => $memcache_pool_maxsize;
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
