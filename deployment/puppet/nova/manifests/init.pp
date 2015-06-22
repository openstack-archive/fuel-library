# == Class: nova
#
# This class is used to specify configuration parameters that are common
# across all nova services.
#
# === Parameters:
#
# [*ensure_package*]
#   (optional) The state of nova packages
#   Defaults to 'present'
#
# [*database_connection*]
#   (optional) Connection url to connect to nova database.
#   Defaults to false
#
# [*slave_connection*]
#   (optional) Connection url to connect to nova slave database (read-only).
#   Defaults to false
#
# [*database_idle_timeout*]
#   (optional) Timeout before idle db connections are reaped.
#   Defaults to 3600
#
# [*rpc_backend*]
#   (optional) The rpc backend implementation to use, can be:
#     rabbit (for rabbitmq)
#     qpid (for qpid)
#     zmq (for zeromq)
#   Defaults to 'rabbit'
#
# [*image_service*]
#   (optional) Service used to search for and retrieve images.
#   Defaults to 'nova.image.local.LocalImageService'
#
# [*glance_api_servers*]
#   (optional) List of addresses for api servers.
#   Defaults to 'localhost:9292'
#
# [*memcached_servers*]
#   (optional) Use memcached instead of in-process cache. Supply a list of memcached server IP's:Memcached Port.
#   Defaults to false
#
# [*rabbit_host*]
#   (optional) Location of rabbitmq installation.
#   Defaults to 'localhost'
#
# [*rabbit_hosts*]
#   (optional) List of clustered rabbit servers.
#   Defaults to false
#
# [*rabbit_port*]
#   (optional) Port for rabbitmq instance.
#   Defaults to '5672'
#
# [*rabbit_password*]
#   (optional) Password used to connect to rabbitmq.
#   Defaults to 'guest'
#
# [*rabbit_userid*]
#   (optional) User used to connect to rabbitmq.
#   Defaults to 'guest'
#
# [*rabbit_virtual_host*]
#   (optional) The RabbitMQ virtual host.
#   Defaults to '/'
#
# [*rabbit_use_ssl*]
#   (optional) Connect over SSL for RabbitMQ
#   Defaults to false
#
# [*rabbit_ha_queues*]
#   (optional) Use HA queues in RabbitMQ.
#   Defaults to undef
#
# [*kombu_ssl_ca_certs*]
#   (optional) SSL certification authority file (valid only if SSL enabled).
#   Defaults to undef
#
# [*kombu_ssl_certfile*]
#   (optional) SSL cert file (valid only if SSL enabled).
#   Defaults to undef
#
# [*kombu_ssl_keyfile*]
#   (optional) SSL key file (valid only if SSL enabled).
#   Defaults to undef
#
# [*kombu_ssl_version*]
#   (optional) SSL version to use (valid only if SSL enabled).
#   Valid values are TLSv1, SSLv23 and SSLv3. SSLv2 may be
#   available on some distributions.
#   Defaults to 'TLSv1'
#
# [*amqp_durable_queues*]
#   (optional) Define queues as "durable" to rabbitmq.
#   Defaults to false
#
# [*qpid_hostname*]
#   (optional) Location of qpid server
#   Defaults to 'localhost'
#
# [*qpid_port*]
#   (optional) Port for qpid server
#   Defaults to '5672'
#
# [*qpid_username*]
#   (optional) Username to use when connecting to qpid
#   Defaults to 'guest'
#
# [*qpid_password*]
#   (optional) Password to use when connecting to qpid
#   Defaults to 'guest'
#
# [*qpid_heartbeat*]
#   (optional) Seconds between connection keepalive heartbeats
#   Defaults to 60
#
# [*qpid_protocol*]
#   (optional) Transport to use, either 'tcp' or 'ssl''
#   Defaults to 'tcp'
#
# [*qpid_sasl_mechanisms*]
#   (optional) Enable one or more SASL mechanisms
#   Defaults to false
#
# [*qpid_tcp_nodelay*]
#   (optional) Disable Nagle algorithm
#   Defaults to true
#
# [*auth_strategy*]
#   (optional) The strategy to use for auth: noauth or keystone.
#   Defaults to 'keystone'
#
# [*service_down_time*]
#   (optional) Maximum time since last check-in for up service.
#   Defaults to 60
#
# [*log_dir*]
#   (optional) Directory where logs should be stored.
#   If set to boolean false, it will not log to any directory.
#   Defaults to '/var/log/nova'
#
# [*state_path*]
#   (optional) Directory for storing state.
#   Defaults to '/var/lib/nova'
#
# [*lock_path*]
#   (optional) Directory for lock files.
#   On RHEL will be '/var/lib/nova/tmp' and on Debian '/var/lock/nova'
#   Defaults to $::nova::params::lock_path
#
# [*verbose*]
#   (optional) Set log output to verbose output.
#   Defaults to false
#
# [*debug*]
#   (optional) Set log output to debug output.
#   Defaults to false
#
# [*periodic_interval*]
#   (optional) Seconds between running periodic tasks.
#   Defaults to '60'
#
# [*report_interval*]
#   (optional) Interval at which nodes report to data store.
#    Defaults to '10'
#
# [*rootwrap_config*]
#   (optional) Path to the rootwrap configuration file to use for running commands as root
#   Defaults to '/etc/nova/rootwrap.conf'
#
# [*use_syslog*]
#   (optional) Use syslog for logging
#   Defaults to false
#
# [*log_facility*]
#   (optional) Syslog facility to receive log lines.
#   Defaults to 'LOG_USER'
#
# [*install_utilities*]
#   (optional) Install nova utilities (Extra packages used by nova tools)
#   Defaults to true,
#
# [*use_ssl*]
#   (optional) Enable SSL on the API server
#   Defaults to false, not set
#
# [*enabled_ssl_apis*]
#   (optional) List of APIs to SSL enable
#   Defaults to []
#   Possible values : 'ec2', 'osapi_compute', 'metadata'
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
#   Defaults to false, not set_
#
# [*nova_public_key*]
#   (optional) Install public key in .ssh/authorized_keys for the 'nova' user.
#   Expects a hash of the form { type => 'key-type', key => 'key-data' } where
#   'key-type' is one of (ssh-rsa, ssh-dsa, ssh-ecdsa) and 'key-data' is the
#   actual key data (e.g, 'AAAA...').
#
# [*nova_private_key*]
#   (optional) Install private key into .ssh/id_rsa (or appropriate equivalent
#   for key type).  Expects a hash of the form { type => 'key-type', key =>
#   'key-data' }, where 'key-type' is one of (ssh-rsa, ssh-dsa, ssh-ecdsa) and
#   'key-data' is the contents of the private key file.
#
# [*mysql_module*]
#   (optional) Deprecated. Does nothing.
#
# [*notification_driver*]
#   (optional) Driver or drivers to handle sending notifications.
#   Value can be a string or a list.
#   Defaults to []
#
# [*notification_topics*]
#   (optional) AMQP topic used for OpenStack notifications
#   Defaults to 'notifications'
#
# [*notify_api_faults*]
#   (optional) If set, send api.fault notifications on caught
#   exceptions in the API service
#   Defaults to false
#
# [*notify_on_state_change*]
#   (optional) If set, send compute.instance.update notifications
#   on instance state changes. Valid values are None for no notifications,
#   "vm_state" for notifications on VM state changes, or "vm_and_task_state"
#   for notifications on VM and task state changes.
#   Defaults to undef
#
# [*os_region_name*]
#   (optional) Sets the os_region_name flag. For environments with
#   more than one endpoint per service, this is required to make
#   things such as cinder volume attach work. If you don't set this
#   and you have multiple endpoints, you will get AmbiguousEndpoint
#   exceptions in the nova API service.
#   Defaults to undef
#
class nova(
  $ensure_package           = 'present',
  $database_connection      = false,
  $slave_connection         = false,
  $database_idle_timeout    = 3600,
  $rpc_backend              = 'rabbit',
  $image_service            = 'nova.image.glance.GlanceImageService',
  # these glance params should be optional
  # this should probably just be configured as a glance client
  $glance_api_servers       = 'localhost:9292',
  $memcached_servers        = false,
  $rabbit_host              = 'localhost',
  $rabbit_hosts             = false,
  $rabbit_password          = 'guest',
  $rabbit_port              = '5672',
  $rabbit_userid            = 'guest',
  $rabbit_virtual_host      = '/',
  $rabbit_use_ssl           = false,
  $rabbit_ha_queues         = undef,
  $kombu_ssl_ca_certs       = undef,
  $kombu_ssl_certfile       = undef,
  $kombu_ssl_keyfile        = undef,
  $kombu_ssl_version        = 'TLSv1',
  $amqp_durable_queues      = false,
  $qpid_hostname            = 'localhost',
  $qpid_port                = '5672',
  $qpid_username            = 'guest',
  $qpid_password            = 'guest',
  $qpid_sasl_mechanisms     = false,
  $qpid_heartbeat           = 60,
  $qpid_protocol            = 'tcp',
  $qpid_tcp_nodelay         = true,
  $auth_strategy            = 'keystone',
  $service_down_time        = 60,
  $log_dir                  = '/var/log/nova',
  $state_path               = '/var/lib/nova',
  $lock_path                = $::nova::params::lock_path,
  $verbose                  = false,
  $debug                    = false,
  $periodic_interval        = '60',
  $report_interval          = '10',
  $rootwrap_config          = '/etc/nova/rootwrap.conf',
  $use_ssl                  = false,
  $enabled_ssl_apis         = ['ec2', 'metadata', 'osapi_compute'],
  $ca_file                  = false,
  $cert_file                = false,
  $key_file                 = false,
  $nova_public_key          = undef,
  $nova_private_key         = undef,
  $use_syslog               = false,
  $log_facility             = 'LOG_USER',
  $install_utilities        = true,
  $notification_driver      = [],
  $notification_topics      = 'notifications',
  $notify_api_faults        = false,
  $notify_on_state_change   = undef,
  # DEPRECATED PARAMETERS
  $mysql_module             = undef,
  $os_region_name           = undef,
) inherits nova::params {

  # maintain backward compatibility
  include ::nova::db

  if $mysql_module {
    warning('The mysql_module parameter is deprecated. The latest 2.x mysql module will be used.')
  }

  validate_array($enabled_ssl_apis)
  if empty($enabled_ssl_apis) and $use_ssl {
      warning('enabled_ssl_apis is empty but use_ssl is set to true')
  }

  if $use_ssl {
    if !$cert_file {
      fail('The cert_file parameter is required when use_ssl is set to true')
    }
    if !$key_file {
      fail('The key_file parameter is required when use_ssl is set to true')
    }
  }

  if $kombu_ssl_ca_certs and !$rabbit_use_ssl {
    fail('The kombu_ssl_ca_certs parameter requires rabbit_use_ssl to be set to true')
  }
  if $kombu_ssl_certfile and !$rabbit_use_ssl {
    fail('The kombu_ssl_certfile parameter requires rabbit_use_ssl to be set to true')
  }
  if $kombu_ssl_keyfile and !$rabbit_use_ssl {
    fail('The kombu_ssl_keyfile parameter requires rabbit_use_ssl to be set to true')
  }
  if ($kombu_ssl_certfile and !$kombu_ssl_keyfile) or ($kombu_ssl_keyfile and !$kombu_ssl_certfile) {
    fail('The kombu_ssl_certfile and kombu_ssl_keyfile parameters must be used together')
  }

  if $nova_public_key or $nova_private_key {
    file { '/var/lib/nova/.ssh':
      ensure  => directory,
      mode    => '0700',
      owner   => 'nova',
      group   => 'nova',
      require => Package['nova-common'],
    }

    if $nova_public_key {
      if ! $nova_public_key['key'] or ! $nova_public_key['type'] {
        fail('You must provide both a key type and key data.')
      }

      ssh_authorized_key { 'nova-migration-public-key':
        ensure  => present,
        key     => $nova_public_key['key'],
        type    => $nova_public_key['type'],
        user    => 'nova',
        require => File['/var/lib/nova/.ssh'],
      }
    }

    if $nova_private_key {
      if ! $nova_private_key[key] or ! $nova_private_key['type'] {
        fail('You must provide both a key type and key data.')
      }

      $nova_private_key_file = $nova_private_key['type'] ? {
        'ssh-rsa'   => '/var/lib/nova/.ssh/id_rsa',
        'ssh-dsa'   => '/var/lib/nova/.ssh/id_dsa',
        'ssh-ecdsa' => '/var/lib/nova/.ssh/id_ecdsa',
        default     => undef
      }

      if ! $nova_private_key_file {
        fail("Unable to determine name of private key file.  Type specified was '${nova_private_key['type']}' but should be one of: ssh-rsa, ssh-dsa, ssh-ecdsa.")
      }

      file { $nova_private_key_file:
        content => $nova_private_key[key],
        mode    => '0600',
        owner   => 'nova',
        group   => 'nova',
        require => [ File['/var/lib/nova/.ssh'], Package['nova-common'] ],
      }
    }
  }


  # all nova_config resources should be applied
  # after the nova common package
  # before the file resource for nova.conf is managed
  # and before the post config resource
  Package['nova-common'] -> Nova_config<| |> -> File['/etc/nova/nova.conf']
  Nova_config<| |> ~> Exec['post-nova_config']

  # TODO - see if these packages can be removed
  # they should be handled as package deps by the OS
  package { 'python-greenlet':
    ensure  => present,
  }

  if $install_utilities {
    class { '::nova::utilities': }
  }

  # this anchor is used to simplify the graph between nova components by
  # allowing a resource to serve as a point where the configuration of nova begins
  anchor { 'nova-start': }

  package { 'python-nova':
    ensure  => $ensure_package,
    require => Package['python-greenlet'],
    tag     => ['openstack'],
  }

  package { 'nova-common':
    ensure  => $ensure_package,
    name    => $::nova::params::common_package_name,
    require => [Package['python-nova'], Anchor['nova-start']],
    tag     => ['openstack'],
  }

  file { '/etc/nova/nova.conf':
    mode    => '0640',
    owner   => 'nova',
    group   => 'nova',
    require => Package['nova-common'],
  }

  # used by debian/ubuntu in nova::network_bridge to refresh
  # interfaces based on /etc/network/interfaces
  exec { 'networking-refresh':
    command     => '/sbin/ifdown -a ; /sbin/ifup -a',
    refreshonly => true,
  }

  nova_config { 'DEFAULT/image_service': value => $image_service }

  if $image_service == 'nova.image.glance.GlanceImageService' {
    if $glance_api_servers {
      nova_config { 'glance/api_servers': value => $glance_api_servers }
    }
  }

  nova_config { 'DEFAULT/auth_strategy': value => $auth_strategy }

  if $memcached_servers {
    nova_config { 'DEFAULT/memcached_servers': value  => join($memcached_servers, ',') }
  } else {
    nova_config { 'DEFAULT/memcached_servers': ensure => absent }
  }

  # we keep "nova.openstack.common.rpc.impl_kombu" for backward compatibility
  # but since Icehouse, "rabbit" is enough.
  if $rpc_backend == 'nova.openstack.common.rpc.impl_kombu' or $rpc_backend == 'rabbit' {
    # I may want to support exporting and collecting these
    nova_config {
      'oslo_messaging_rabbit/rabbit_password':     value => $rabbit_password, secret => true;
      'oslo_messaging_rabbit/rabbit_userid':       value => $rabbit_userid;
      'oslo_messaging_rabbit/rabbit_virtual_host': value => $rabbit_virtual_host;
      'oslo_messaging_rabbit/rabbit_use_ssl':      value => $rabbit_use_ssl;
      'DEFAULT/amqp_durable_queues': value => $amqp_durable_queues;
    }

    if $rabbit_use_ssl {

      if $kombu_ssl_ca_certs {
        nova_config { 'oslo_messaging_rabbit/kombu_ssl_ca_certs': value => $kombu_ssl_ca_certs; }
      } else {
        nova_config { 'oslo_messaging_rabbit/kombu_ssl_ca_certs': ensure => absent; }
      }

      if $kombu_ssl_certfile or $kombu_ssl_keyfile {
        nova_config {
          'oslo_messaging_rabbit/kombu_ssl_certfile': value => $kombu_ssl_certfile;
          'oslo_messaging_rabbit/kombu_ssl_keyfile':  value => $kombu_ssl_keyfile;
        }
      } else {
        nova_config {
          'oslo_messaging_rabbit/kombu_ssl_certfile': ensure => absent;
          'oslo_messaging_rabbit/kombu_ssl_keyfile':  ensure => absent;
        }
      }

      if $kombu_ssl_version {
        nova_config { 'oslo_messaging_rabbit/kombu_ssl_version':  value => $kombu_ssl_version; }
      } else {
        nova_config { 'oslo_messaging_rabbit/kombu_ssl_version':  ensure => absent; }
      }

    } else {
      nova_config {
        'oslo_messaging_rabbit/kombu_ssl_ca_certs': ensure => absent;
        'oslo_messaging_rabbit/kombu_ssl_certfile': ensure => absent;
        'oslo_messaging_rabbit/kombu_ssl_keyfile':  ensure => absent;
        'oslo_messaging_rabbit/kombu_ssl_version':  ensure => absent;
      }
    }

    if $rabbit_hosts {
      nova_config { 'oslo_messaging_rabbit/rabbit_hosts':     value => join($rabbit_hosts, ',') }
    } else {
      nova_config { 'oslo_messaging_rabbit/rabbit_host':      value => $rabbit_host }
      nova_config { 'oslo_messaging_rabbit/rabbit_port':      value => $rabbit_port }
      nova_config { 'oslo_messaging_rabbit/rabbit_hosts':     value => "${rabbit_host}:${rabbit_port}" }
    }
    if $rabbit_ha_queues == undef {
      if $rabbit_hosts {
        nova_config { 'oslo_messaging_rabbit/rabbit_ha_queues': value => true }
      } else {
        nova_config { 'oslo_messaging_rabbit/rabbit_ha_queues': value => false }
      }
    } else {
      nova_config { 'oslo_messaging_rabbit/rabbit_ha_queues': value => $rabbit_ha_queues }
    }
  }

  # we keep "nova.openstack.common.rpc.impl_qpid" for backward compatibility
  # but since Icehouse, "qpid" is enough.
  if $rpc_backend == 'nova.openstack.common.rpc.impl_qpid' or $rpc_backend == 'qpid' {
    nova_config {
      'DEFAULT/qpid_hostname':               value => $qpid_hostname;
      'DEFAULT/qpid_port':                   value => $qpid_port;
      'DEFAULT/qpid_username':               value => $qpid_username;
      'DEFAULT/qpid_password':               value => $qpid_password, secret => true;
      'DEFAULT/qpid_heartbeat':              value => $qpid_heartbeat;
      'DEFAULT/qpid_protocol':               value => $qpid_protocol;
      'DEFAULT/qpid_tcp_nodelay':            value => $qpid_tcp_nodelay;
    }
    if is_array($qpid_sasl_mechanisms) {
      nova_config {
        'DEFAULT/qpid_sasl_mechanisms': value => join($qpid_sasl_mechanisms, ' ');
      }
    }
    elsif $qpid_sasl_mechanisms {
      nova_config {
        'DEFAULT/qpid_sasl_mechanisms': value => $qpid_sasl_mechanisms;
      }
    }
    else {
      nova_config {
        'DEFAULT/qpid_sasl_mechanisms': ensure => absent;
      }
    }
  }

  # SSL Options
  if $use_ssl {
    nova_config {
      'DEFAULT/enabled_ssl_apis' : value => join($enabled_ssl_apis, ',');
      'DEFAULT/ssl_cert_file' :    value => $cert_file;
      'DEFAULT/ssl_key_file' :     value => $key_file;
    }
    if $ca_file {
      nova_config { 'DEFAULT/ssl_ca_file' :
        value => $ca_file,
      }
    } else {
      nova_config { 'DEFAULT/ssl_ca_file' :
        ensure => absent,
      }
    }
  } else {
    nova_config {
      'DEFAULT/enabled_ssl_apis' : ensure => absent;
      'DEFAULT/ssl_cert_file' :    ensure => absent;
      'DEFAULT/ssl_key_file' :     ensure => absent;
      'DEFAULT/ssl_ca_file' :      ensure => absent;
    }
  }

  if $log_dir {
    file { $log_dir:
      ensure  => directory,
      mode    => '0750',
      owner   => 'nova',
      group   => $::nova::params::nova_log_group,
      require => Package['nova-common'],
    }
    nova_config { 'DEFAULT/log_dir': value => $log_dir;}
  } else {
    nova_config { 'DEFAULT/log_dir': ensure => absent;}
  }

  $notification_driver_real = is_string($notification_driver) ? {
    true    => $notification_driver,
    default => join($notification_driver, ',')
  }

  nova_config {
    'DEFAULT/verbose':             value => $verbose;
    'DEFAULT/debug':               value => $debug;
    'DEFAULT/rpc_backend':         value => $rpc_backend;
    'DEFAULT/notification_driver': value => $notification_driver_real;
    'DEFAULT/notification_topics': value => $notification_topics;
    'DEFAULT/notify_api_faults':   value => $notify_api_faults;
    # Following may need to be broken out to different nova services
    'DEFAULT/state_path':          value => $state_path;
    'DEFAULT/lock_path':           value => $lock_path;
    'DEFAULT/service_down_time':   value => $service_down_time;
    'DEFAULT/rootwrap_config':     value => $rootwrap_config;
    'DEFAULT/report_interval':     value => $report_interval;
  }

  if $notify_on_state_change and $notify_on_state_change in ['vm_state', 'vm_and_task_state'] {
    nova_config {
      'DEFAULT/notify_on_state_change': value => $notify_on_state_change;
    }
  } else {
    nova_config { 'DEFAULT/notify_on_state_change': ensure => absent; }
  }

  # Syslog configuration
  if $use_syslog {
    nova_config {
      'DEFAULT/use_syslog':           value => true;
      'DEFAULT/syslog_log_facility':  value => $log_facility;
    }
  } else {
    nova_config {
      'DEFAULT/use_syslog':           value => false;
    }
  }

  if $os_region_name {
    nova_config {
      'DEFAULT/os_region_name':       value => $os_region_name;
    }
  }
  else {
    nova_config {
      'DEFAULT/os_region_name':       ensure => absent;
    }
  }

  exec { 'post-nova_config':
    command     => '/bin/echo "Nova config has changed"',
    refreshonly => true,
  }

}
