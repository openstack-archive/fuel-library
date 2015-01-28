$glance_hash = hiera('glance_hash')

class { 'mysql::config' :
  bind_address       => $internal_address,
  use_syslog         => hiera('use_syslog'),
  custom_setup_class => hiera('deployment_mode')? {
                         ha => 'galera',
                         ha_compact => 'galera',
                         default => undef
			},
  config_file        => {
    'config_file' => '/etc/my.cnf'
  },
}

class { 'glance::db::mysql':
    user          => 'glance',
    password      => $glance_hash['db_password'],
    dbname        => 'glance',
    allowed_hosts => [ '%', $::hostname ],
  }
Class['glance::db::mysql'] -> Class['::glance']

class { 'glance::keystone::auth':
        password         => $glance_hash['user_password'],
        public_address   => hiera('public_vip'),
        admin_address    => hiera('management_vip'),
        internal_address => hiera('management_vip'),
}
Class['glance::keystone::auth'] -> Class['::glance']

$internal_address = hiera('internal_address')
$storage_hash = hiera('storage_hash')
$db_host = hiera('management_vip')
$glance_db_password = $glance_hash['db_password']
$sql_connection = "mysql://glance:${glance_db_password}@${db_host}/glance?read_timeout=60"
$idle_timeout = '3600'
$keystone_host = hiera('management_vip')
$bind_host = $internal_address
$use_syslog = hiera('use_syslog')

if ($storage_hash['images_ceph']) {
    $glance_backend = 'ceph'
    $glance_known_stores = [ 'glance.store.rbd.Store', 'glance.store.http.Store' ]
  } elsif ($storage_hash['images_vcenter']) {
    $glance_backend = 'vmware'
    $glance_known_stores = [ 'glance.store.vmware_datastore.Store', 'glance.store.http.Store' ]
  } else {
    $glance_backend = 'swift'
    $glance_known_stores = [ 'glance.store.swift.Store', 'glance.store.http.Store' ]
  }


# Install and configure glance-api
class { 'glance::api':
    verbose               => hiera('verbose'),
    debug                 => hiera('debug'),
    bind_host             => $bind_host,
    auth_type             => 'keystone',
    auth_port             => '35357',
    auth_host             => $keystone_host,
    keystone_tenant       => 'services',
    keystone_user         => 'glance',
    keystone_password     => $glance_hash['user_password'],
    sql_connection        => $sql_connection,
    enabled               => true,
    registry_host         => hiera('management_vip'),
    use_syslog            => $use_syslog,
    log_facility          => hiera('syslog_log_facility_glance'),
    sql_idle_timeout      => $idle_timeout,
    show_image_direct_url => true,
    pipeline              => 'keystone+cachemanagement',
    known_stores          => $glance_known_stores,
  }

$max_pool_size = '10'
$max_retries = '-1'
$max_overflow = '30'

  glance_api_config {
    'DEFAULT/control_exchange':           value => "glance";
    'DEFAULT/sql_max_pool_size':          value => $max_pool_size;
    'DEFAULT/sql_max_retries':            value => $max_retries;
    'DEFAULT/sql_max_overflow':           value => $max_overflow;
    'DEFAULT/registry_client_protocol':   value => "http";
    'DEFAULT/delayed_delete':             value => "False";
    'DEFAULT/scrub_time':                 value => "43200";
    'DEFAULT/scrubber_datadir':           value => "/var/lib/glance/scrubber";
    'DEFAULT/image_cache_dir':            value => "/var/lib/glance/image-cache/";
    'keystone_authtoken/signing_dir':     value => '/tmp/keystone-signing-glance';
    'keystone_authtoken/signing_dirname': value => '/tmp/keystone-signing-glance';
  }

$glance_image_cache_max_size = $glance_hash['image_cache_max_size']

  glance_cache_config {
    'DEFAULT/sql_max_pool_size':                      value => $max_pool_size;
    'DEFAULT/sql_max_retries':                        value => $max_retries;
    'DEFAULT/sql_max_overflow':                       value => $max_overflow;
    'DEFAULT/use_syslog':                             value => $use_syslog;
    'DEFAULT/image_cache_dir':                        value => "/var/lib/glance/image-cache/";
    'DEFAULT/log_file':                               value => "/var/log/glance/image-cache.log";
    'DEFAULT/image_cache_stall_time':                 value => "86400";
    'DEFAULT/image_cache_invalid_entry_grace_period': value => "3600";
    'DEFAULT/image_cache_max_size':                   value => $glance_image_cache_max_size;
  }

  # Install and configure glance-registry
  class { 'glance::registry':
    verbose             => hiera('verbose'),
    debug               => hiera('debug'),
    bind_host           => $bind_host,
    auth_host           => $keystone_host,
    auth_port           => '35357',
    auth_type           => 'keystone',
    keystone_tenant     => 'services',
    keystone_user       => 'glance',
    keystone_password   => $glance_hash['user_password'],
    sql_connection      => $sql_connection,
    enabled             => true,
    use_syslog          => $use_syslog,
    log_facility        => hiera('syslog_log_facility_glance'),
    sql_idle_timeout    => $idle_timeout,
  }

  glance_registry_config {
    'DEFAULT/sql_max_pool_size':          value => $max_pool_size;
    'DEFAULT/sql_max_retries':            value => $max_retries;
    'DEFAULT/sql_max_overflow':           value => $max_overflow;
    'keystone_authtoken/signing_dir':     value => '/tmp/keystone-signing-glance';
    'keystone_authtoken/signing_dirname': value => '/tmp/keystone-signing-glance';
  }

  # puppet-glance assumes rabbit_hosts is an array of [node:port, node:port]
  # but we pass it as a amqp_hosts string of 'node:port, node:port' in Fuel
  if !is_array($rabbit_hosts) {
    $rabbit_hosts_real = split($rabbit_hosts, ',')
    glance_api_config {
      'DEFAULT/kombu_reconnect_delay': value => 5.0;
    }
  } else {
    $rabbit_hosts_real = $rabbit_hosts
  }

$rabbit_hash     = hiera('rabbit_hash',
    {
      'user'     => false,
      'password' => false,
    }
  )


  # Configure rabbitmq notifications
  # TODO(bogdando) sync qpid support from upstream
  class { 'glance::notify::rabbitmq':
    rabbit_password              => $rabbit_hash['password'],
    rabbit_userid                => $rabbit_hash['user'],
    rabbit_hosts                 => split( hiera('amqp_hosts'), ','),
    rabbit_host                  => 'localhost',
    rabbit_port                  => '5673',
    rabbit_virtual_host          => '/',
    rabbit_use_ssl               => false,
    rabbit_notification_exchange => 'glance',
    rabbit_notification_topic    => 'notifications',
    amqp_durable_queues          => false,
  }

  glance_api_config {
    'DEFAULT/notification_strategy': value => 'rabbit';
  }

  # syslog additional settings default/use_syslog_rfc_format = true
  if $use_syslog {
    glance_api_config {
      'DEFAULT/use_syslog_rfc_format': value => true;
    }
    glance_cache_config {
      'DEFAULT/use_syslog_rfc_format': value => true;
    }
    glance_registry_config {
      'DEFAULT/use_syslog_rfc_format': value => true;
    }
  }

  # Configure file storage backend

  case $glance_backend {
    'swift': {
      if !defined(Package['swift']) {
        include ::swift::params
        package { "swift":
          name   => $::swift::params::package_name,
          ensure =>present
        }
      }
      Package['swift'] ~> Service['glance-api']
      Package['swift'] -> Swift::Ringsync <||>
      Package<| title == 'swift'|> ~> Service<| title == 'glance-api'|>
      if !defined(Service['glance-api']) {
        notify{ "Module ${module_name} cannot notify service glance-api on package swift update": }
      }
      class { "glance::backend::$glance_backend":
        swift_store_user => "services:glance",
        swift_store_key=> $glance_hash['user_password'],
        swift_store_create_container_on_put => "True",
        swift_store_large_object_size => '200',
        swift_store_auth_address => "http://${keystone_host}:5000/v2.0/"
      }
    }
    'rbd', 'ceph': {
      Ceph::Pool<| title == $::ceph::glance_pool |> ->
      class { "glance::backend::rbd":
        rbd_store_user => $::ceph::glance_user,
        rbd_store_pool => $::ceph::glance_pool,
      }
    }
    'vmware': {
      class { "glance::backend::vsphere":
          vcenter_host        => $storage_hash['vc_host'],
          vcenter_user        => $storage_hash['vc_user'],
          vcenter_password    => $glance_hash['vc_password'],
          vcenter_datacenter  => $glance_hash['vc_datacenter'],
          vcenter_datastore   => $glance_hash['vc_datastore'],
          vcenter_image_dir   => $glance_hash['vc_image_dir'],
      }
    }
    default: {
      class { "glance::backend::$glance_backend": }
    }
  }

if($::operatingsystem == 'Ubuntu') {
  tweaks::ubuntu_service_override { 'glance-api':
    package_name => 'glance-api',
  }
  tweaks::ubuntu_service_override { 'glance-registry':
    package_name => 'glance-registry',
  }
}

Haproxy::Service        { use_include => true }
Haproxy::Balancermember { use_include => true }

Cluster::Haproxy_service {
  server_names           => hiera('controller_hostnames'),
  ipaddresses            => hiera('controller_nodes'),
  public_virtual_ip      => hiera('public_vip'),
  internal_virtual_ip    => hiera('management_vip'),
}

cluster::haproxy_service { 'glance-registry':
  order           => '090',
  listen_port     => 9191,
  require_service => 'glance-registry',
}

cluster::haproxy_service { 'glance-api':
  order                  => '080',
  listen_port            => 9292,
  public                 => true,
  require_service        => 'glance-api',
  haproxy_config_options => {
      option => ['httpchk', 'httplog','httpclose'],
  },
  balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
}

