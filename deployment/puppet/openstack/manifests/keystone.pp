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
# [glance_user_password] Auth password for glance user. Required.
# [nova_user_password] Auth password for nova user. Required.
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
# [glance] Set up glance endpoints and auth. Optional. Defaults to  true
# [nova] Set up nova endpoints and auth. Optional. Defaults to  true
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
#   keystone_admin_token  => '12345',
#   admin_email           => 'root@localhost',
#   admin_password        => 'changeme',
#   public_address        => '192.168.1.1',
#  }

class openstack::keystone (
  $db_host,
  $db_password,
  $admin_token,
  $glance_user_password,
  $nova_user_password,
  $cinder_user_password,
  $ceilometer_user_password,
  $neutron_user_password,
  $public_address,
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
  $glance_public_address       = false,
  $glance_internal_address     = false,
  $glance_admin_address        = false,
  $nova_public_address         = false,
  $nova_internal_address       = false,
  $nova_admin_address          = false,
  $cinder_public_address       = false,
  $cinder_internal_address     = false,
  $cinder_admin_address        = false,
  $neutron_public_address      = false,
  $neutron_internal_address    = false,
  $neutron_admin_address       = false,
  $ceilometer_public_address   = false,
  $ceilometer_internal_address = false,
  $ceilometer_admin_address    = false,
  $glance                      = true,
  $nova                        = true,
  $cinder                      = true,
  $ceilometer                  = true,
  $neutron                     = true,
  $enabled                     = true,
  $package_ensure              = present,
  $use_syslog                  = false,
  $syslog_log_facility         = 'LOG_LOCAL7',
  $idle_timeout                = '200',
  $rabbit_hosts                = false,
  $rabbit_password             = 'guest',
  $rabbit_userid               = 'guest',
  $rabbit_virtual_host         = '/',
  $max_pool_size               = '10',
  $max_overflow                = '30',
  $max_retries                 = '-1',
) {

  # Install and configure Keystone
  if $db_type == 'mysql' {
    $sql_conn = "mysql://${$db_user}:${db_password}@${db_host}/${db_name}?read_timeout=60"
  } else {
    fail("db_type ${db_type} is not supported")
  }

  # I have to do all of this crazy munging b/c parameters are not
  # set procedurally in Pupet
  if($internal_address) {
    $internal_real = $internal_address
  } else {
    $internal_real = $public_address
  }
  if($admin_address) {
    $admin_real = $admin_address
  } else {
    $admin_real = $internal_real
  }
  if($glance_public_address) {
    $glance_public_real = $glance_public_address
  } else {
    $glance_public_real = $public_address
  }
  if($glance_internal_address) {
    $glance_internal_real = $glance_internal_address
  } else {
    $glance_internal_real = $internal_real
  }
  if($glance_admin_address) {
    $glance_admin_real = $glance_admin_address
  } else {
    $glance_admin_real = $admin_real
  }
  if($nova_public_address) {
    $nova_public_real = $nova_public_address
  } else {
    $nova_public_real = $public_address
  }
  if($nova_internal_address) {
    $nova_internal_real = $nova_internal_address
  } else {
    $nova_internal_real = $internal_real
  }
  if($nova_admin_address) {
    $nova_admin_real = $nova_admin_address
  } else {
    $nova_admin_real = $admin_real
  }
  if($cinder_public_address) {
    $cinder_public_real = $cinder_public_address
  } else {
    $cinder_public_real = $public_address
  }
  if($cinder_internal_address) {
    $cinder_internal_real = $cinder_internal_address
  } else {
    $cinder_internal_real = $internal_real
  }
  if($cinder_admin_address) {
    $cinder_admin_real = $cinder_admin_address
  } else {
    $cinder_admin_real = $admin_real
  }
  if($neutron_public_address) {
    $neutron_public_real = $neutron_public_address
  } else {
    $neutron_public_real = $public_address
  }
  if($neutron_internal_address) {
    $neutron_internal_real = $neutron_internal_address
  } else {
    $neutron_internal_real = $internal_real
  }
  if($neutron_admin_address) {
    $neutron_admin_real = $neutron_admin_address
  } else {
    $neutron_admin_real = $admin_real
  }
  if($ceilometer_public_address) {
    $ceilometer_public_real = $ceilometer_public_address
  } else {
    $ceilometer_public_real = $public_address
  }
  if($ceilometer_internal_address) {
    $ceilometer_internal_real = $ceilometer_internal_address
  } else {
    $ceilometer_internal_real = $internal_real
  }
  if($ceilometer_admin_address) {
    $ceilometer_admin_real = $ceilometer_admin_address
  } else {
    $ceilometer_admin_real = $admin_real
  }
  if($ceilometer) {
    $notification_driver = 'messaging'
    $notification_topics = 'notifications'
  } else {
    $notification_driver = false
    $notification_topics = false
  }

  if $memcache_servers {
    $memcache_servers_real = suffix($memcache_servers, inline_template(":<%= @memcache_server_port %>"))
    $token_driver = 'keystone.token.persistence.backends.memcache_pool.Token'
  } else {
    $memcache_servers_real = false
    $token_driver = 'keystone.token.backends.sql.Token'
  }

  class { '::keystone':
    verbose             => $verbose,
    debug               => $debug,
    catalog_type        => 'sql',
    admin_token         => $admin_token,
    enabled             => $enabled,
    sql_connection      => $sql_conn,
    public_bind_host    => $public_bind_host,
    admin_bind_host     => $admin_bind_host,
    package_ensure      => $package_ensure,
    use_syslog          => $use_syslog,
    idle_timeout        => $idle_timeout,
    rabbit_password     => $rabbit_password,
    rabbit_userid       => $rabbit_userid,
    rabbit_hosts        => $rabbit_hosts,
    rabbit_virtual_host => $rabbit_virtual_host,
    memcache_servers    => $memcache_servers_real,
    token_driver        => $token_driver,
    token_provider      => 'keystone.token.providers.uuid.Provider',
    notification_driver => $notification_driver,
    notification_topics => $notification_topics,
  }

  if $::operatingsystem == 'Ubuntu' {
   if $service_provider == 'pacemaker' {
      tweaks::ubuntu_service_override { 'keystone':
        package_name => 'keystone',
      }
      exec { 'remove-keystone-bootblockr':
        command => 'rm -rf /etc/init/keystone.override',
        path    => ['/bin', '/usr/bin'],
        require => Package['keystone']
      }
    }
  }

  if $memcache_servers {
    Service<| title == 'memcached' |> -> Service<| title == 'keystone'|>
    keystone_config {
      'token/caching':                      value => 'false';
      'cache/enabled':                      value => 'true';
      'cache/backend':                      value => 'keystone.cache.memcache_pool';
      'cache/memcache_servers':             value => join($memcache_servers_real, ',');
      'cache/memcache_dead_retry':          value => '30';
      'cache/memcache_socket_timeout':      value => '1';
      'cache/memcache_pool_maxsize':        value => '1000';
      'cache/memcache_pool_unused_timeout': value => '60';
      'memcache/dead_retry':                value => '30';
      'revoke/driver':                      value => 'keystone.contrib.revoke.backends.sql.Revoke';
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
    'identity/driver':                                 value =>"keystone.identity.backends.sql.Identity";
    'policy/driver':                                   value =>"keystone.policy.backends.sql.Policy";
    'ec2/driver':                                      value =>"keystone.contrib.ec2.backends.sql.Ec2";
    'filter:debug/paste.filter_factory':               value =>"keystone.common.wsgi:Debug.factory";
    'filter:token_auth/paste.filter_factory':          value =>"keystone.middleware:TokenAuthMiddleware.factory";
    'filter:admin_token_auth/paste.filter_factory':    value =>"keystone.middleware:AdminTokenAuthMiddleware.factory";
    'filter:xml_body/paste.filter_factory':            value =>"keystone.middleware:XmlBodyMiddleware.factory";
    'filter:json_body/paste.filter_factory':           value =>"keystone.middleware:JsonBodyMiddleware.factory";
    'filter:user_crud_extension/paste.filter_factory': value =>"keystone.contrib.user_crud:CrudExtension.factory";
    'filter:crud_extension/paste.filter_factory':      value =>"keystone.contrib.admin_crud:CrudExtension.factory";
    'filter:ec2_extension/paste.filter_factory':       value =>"keystone.contrib.ec2:Ec2Extension.factory";
    'filter:s3_extension/paste.filter_factory':        value =>"keystone.contrib.s3:S3Extension.factory";
    'filter:url_normalize/paste.filter_factory':       value =>"keystone.middleware:NormalizingFilter.factory";
    'filter:stats_monitoring/paste.filter_factory':    value =>"keystone.contrib.stats:StatsMiddleware.factory";
    'filter:stats_reporting/paste.filter_factory':     value =>"keystone.contrib.stats:StatsExtension.factory";
    'app:public_service/paste.app_factory':            value =>"keystone.service:public_app_factory";
    'app:admin_service/paste.app_factory':             value =>"keystone.service:admin_app_factory";
    'pipeline:public_api/pipeline':                    value =>"stats_monitoring url_normalize token_auth admin_token_auth xml_body json_body debug ec2_extension user_crud_extension public_service";
    'pipeline:admin_api/pipeline':                     value =>"stats_monitoring url_normalize token_auth admin_token_auth xml_body json_body debug stats_reporting ec2_extension s3_extension crud_extension admin_service";
    'app:public_version_service/paste.app_factory':    value =>"keystone.service:public_version_app_factory";
    'app:admin_version_service/paste.app_factory':     value =>"keystone.service:admin_version_app_factory";
    'pipeline:public_version_api/pipeline':            value =>"stats_monitoring url_normalize xml_body public_version_service";
    'pipeline:admin_version_api/pipeline':             value =>"stats_monitoring url_normalize xml_body admin_version_service";
    'composite:main/use':                              value =>"egg:Paste#urlmap";
    'composite:main//v2.0':                            value =>"public_api";
    'composite:main//':                                value =>"public_version_api";
    'composite:admin/use':                             value =>"egg:Paste#urlmap";
    'composite:admin//v2.0':                           value =>"admin_api";
    'composite:admin//':                               value =>"admin_version_api";
  }

  if ($enabled) {
    # Setup the admin user

    # Setup the Keystone Identity Endpoint
    class { 'keystone::endpoint':
      public_address   => $public_address,
      admin_address    => $admin_real,
      internal_address => $internal_real,
    }
    Exec <| title == 'keystone-manage db_sync' |> -> Class['keystone::endpoint']
    Haproxy_backend_status<||> -> Class['keystone::endpoint']

    # Configure Glance endpoint in Keystone
    if $glance {
      class { 'glance::keystone::auth':
        password         => $glance_user_password,
        public_address   => $glance_public_real,
        admin_address    => $glance_admin_real,
        internal_address => $glance_internal_real,
      }
      Exec <| title == 'keystone-manage db_sync' |> -> Class['glance::keystone::auth']
      Haproxy_backend_status<||> -> Class['glance::keystone::auth']
    }

    # Configure Nova endpoint in Keystone
    if $nova {
      class { 'nova::keystone::auth':
        password         => $nova_user_password,
        public_address   => $nova_public_real,
        admin_address    => $nova_admin_real,
        internal_address => $nova_internal_real,
      }
      Exec <| title == 'keystone-manage db_sync' |> -> Class['nova::keystone::auth']
      Haproxy_backend_status<||> -> Class['nova::keystone::auth']
    }

    # Configure Cinder endpoint in Keystone
    if $cinder {
      class { 'cinder::keystone::auth':
        password         => $cinder_user_password,
        public_address   => $cinder_public_real,
        admin_address    => $cinder_admin_real,
        internal_address => $cinder_internal_real,
      }
     Exec <| title == 'keystone-manage db_sync' |> -> Class['cinder::keystone::auth']
     Haproxy_backend_status<||> -> Class['cinder::keystone::auth']
    }
    if $neutron {
      class { 'neutron::keystone::auth':
        password         => $neutron_user_password,
        public_address   => $neutron_public_real,
        admin_address    => $neutron_admin_real,
        internal_address => $neutron_internal_real,
      }
      Exec <| title == 'keystone-manage db_sync' |> -> Class['neutron::keystone::auth']
      Haproxy_backend_status<||> -> Class['neutron::keystone::auth']
    }
    if $ceilometer {
      class { 'ceilometer::keystone::auth':
        password         => $ceilometer_user_password,
        public_address   => $ceilometer_public_real,
        admin_address    => $ceilometer_admin_real,
        internal_address => $ceilometer_internal_real,
      }
      Exec <| title == 'keystone-manage db_sync' |> -> Class['ceilometer::keystone::auth']
      Haproxy_backend_status<||> -> Class['ceilometer::keystone::auth']
    }
  }

}
