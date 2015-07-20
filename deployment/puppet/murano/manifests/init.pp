# == Class: murano
#
#  murano base package & configuration
#
# === Parameters
#
# [*package_ensure*]
#  (Optional) Ensure state for package
#  Defaults to 'present'
#
# [*verbose*]
#  (Optional) Should the service log verbose messages
#  Defaults to false
#
# [*debug*]
#  (Optional) Should the service log debug messages
#  Defaults to false
#
# [*use_syslog*]
#  (Optional) Should the service use Syslog
#  Defaults to false
#
# [*log_facility*]
#  (Optional) Syslog facility to recieve logs
#  Defaults to 'LOG_LOCAL0'
#
# [*log_dir*]
#  (Optional) Directory to store logs
#  Defaults to '/var/log/murano'
#
# [*data_dir*]
#  (Optional) Directory to store data
#  Defaults to '/var/cache/murano'
#
# [*notification_driver*]
#  (Optional) Notification driver to use
#  Defaults to 'messagingv2'
#
# [*rabbit_os_host*]
#  (Optional) Host for openstack rabbit server
#  Defaults to '127.0.0.1'
#
# [*rabbit_os_port*]
#  (Optional) Port for openstack rabbit server
#  Defaults to '5672'
#
# [*rabbit_os_user*]
#  (Optional) Username for openstack rabbit server
#  Defaults to 'guest'
#
# [*rabbit_os_password*]
#  (Optional) Password for openstack rabbit server
#  Defaults to 'guest'
#
# [*rabbit_ha_queues*]
#  (Optional) Should murano api use ha queues
#  Defaults to 'guest'
#
# [*rabbit_own_host*]
#  (Optional) Host for murano rabbit server
#  Defaults to '127.0.0.1'
#
# [*rabbit_own_port*]
#  (Optional) Port for murano rabbit server
#  Defaults to '5672'
#
# [*rabbit_own_user*]
#  (Optional) Username for murano rabbit server
#  Defaults to 'guest'
#
# [*rabbit_own_password*]
#  (Optional) Password for murano rabbit server
#  Defaults to 'guest'
#
# [*service_host*]
#  (Optional) Host for murano to listen on
#  Defaults to '0.0.0.0'
#
# [*service_port*]
#  (Optional) Port for murano to listen on
#  Defaults to 8082
#
# [*database_connection*]
#  (Optional) Database for murano
#  Defaults to 'mysql://murano:secrete@localhost:3306/murano'
#
# == keystone authentication options
#
# [*keystone_username*]
#  (Optional) Username for murano credentials
#  Defaults to 'admin'
#
# [*keystone_password*]
#  (Optional) Password for murano credentials
#  Defaults to false
#
# [*keystone_tenant*]
#  (Optional) Tenant for keystone_username
#  Defaults to 'admin'
#
# [*keystone_region*]
#  (Optional) Region for keystone
#  Defaults to 'RegionOne'
#
# [*keystone_uri*]
#  (Optional) Public identity endpoint
#  Defaults to 'http://127.0.0.1:5000/v2.0/'
#
# [*keystone_signing_dir*]
#  (Optional) Directory used to cache files related to PKI tokens
#  Defaults to '/tmp/keystone-signing-muranoapi'
#
# [*identity_uri*]
#  (Optional) Admin identity endpoint
#  Defaults to 'http://127.0.0.1:35357/'#
#
# [*use_neutron*]
#  (Optional) Whet
#  Defaults to false
#
# [*external_network*]
#  (Optional)
#  Defaults to 'public'
#
# [*default_router*]
#  (Optional)
#  Defaults to 'murano-default-router'
#
class murano(
  $package_ensure       = 'present',
  $verbose              = false,
  $debug                = false,
  $use_syslog           = false,
  $log_facility         = 'LOG_LOCAL0',
  $log_dir              = '/var/log/murano',
  $data_dir             = '/var/cache/murano',
  $notification_driver  = 'messagingv2',
  $rabbit_os_host       = '127.0.0.1',
  $rabbit_os_port       = '5672',
  $rabbit_os_user       = 'guest',
  $rabbit_os_password   = 'guest',
  $rabbit_ha_queues     = false,
  $rabbit_own_host      = '127.0.0.1',
  $rabbit_own_port      = '5672',
  $rabbit_own_user      = 'guest',
  $rabbit_own_password  = 'guest',
  $service_host         = '127.0.0.1',
  $service_port         = 8082,
  $database_connection  = 'mysql://murano:secrete@localhost:3306/murano',
  $keystone_username    = 'admin',
  $keystone_password    = false,
  $keystone_tenant      = 'admin',
  $keystone_region      = 'RegionOne',
  $keystone_uri         = 'http://127.0.0.1:5000/v2.0/',
  $keystone_signing_dir = '/tmp/keystone-signing-muranoapi',
  $identity_uri         = 'http://127.0.0.1:35357/',
  $use_neutron          = false,
  $external_network     = 'public',
  $default_router       = 'murano-default-router',
) {

  include ::murano::params
  include ::murano::policy

  Package['murano-common'] -> Murano_config<| |> -> File['/etc/murano/murano.conf']

  group { 'murano':
    ensure => present,
    system => true,
  }

  $murano_user_shell = $::osfamily ? {
    'RedHat' => '/sbin/nologin',
    'Debian' => '/usr/sbin/nologin',
    default  => '/sbin/nologin',
  }

  user { 'murano':
    ensure  => present,
    comment => 'Murano User',
    gid     => 'murano',
    system  => true,
    shell   => $murano_user_shell,
    require => Group['murano'],
  }

  file { $data_dir:
    ensure => directory,
    owner  => 'murano',
    group  => 'murano',
    mode   => '0755',
  }

  file { $log_dir:
    ensure => directory,
    owner  => 'murano',
    group  => 'murano',
    mode   => '0750',
  }

  package { 'murano-common':
    ensure => $package_ensure,
    name   => $::murano::params::common_package_name,
    tag    => ['openstack'],
  }

  file { '/etc/murano/murano.conf':
    mode    => '0640',
    owner   => 'murano',
    group   => 'murano',
    require => Package['murano-common'],
  }

  validate_re($database_connection, '(sqlite|mysql|postgresql):\/\/(\S+:\S+@\S+\/\S+)?')

  case $database_connection {
    /^mysql:\/\//: {
      require mysql::bindings
      require mysql::bindings::python
    }
    /^postgresql:\/\//: {
      require postgresql::lib::python
    }
    /^sqlite:\/\//: {
      fail('murano does not support sqlite!')
    }
    default: {
      fail('Unsupported db backend configured')
    }
  }

  if $use_syslog {
    murano_config {
      'DEFAULT/use_syslog'           : value => true;
      'DEFAULT/use_syslog_rfc_format': value => true;
      'DEFAULT/syslog_log_facility'  : value => $log_facility;
    }
  }

  if $use_neutron {
    murano_config {
      'networking/external_network' : value => $external_network;
      'networking/router_name'      : value => $default_router;
      'networking/create_router'    : value => true;
    }
  }

  murano_config {
    'DEFAULT/verbose'                       : value => $verbose;
    'DEFAULT/debug'                         : value => $debug;
    'DEFAULT/log_dir'                       : value => $log_dir;
    'DEFAULT/notification_driver'           : value => $notification_driver;

    'murano/url'                            : value => "http://${service_host}:${service_port}";

    'database/connection'                   : value => $database_connection;

    'oslo_messaging_rabbit/rabbit_userid'   : value => $rabbit_os_user;
    'oslo_messaging_rabbit/rabbit_password' : value => $rabbit_os_password;
    'oslo_messaging_rabbit/rabbit_hosts'    : value => $rabbit_os_host;
    'oslo_messaging_rabbit/rabbit_port'     : value => $rabbit_os_port;
    'oslo_messaging_rabbit/rabbit_ha_queues': value => $rabbit_ha_queues;

    'rabbitmq/login'                        : value => $rabbit_own_user;
    'rabbitmq/password'                     : value => $rabbit_own_password;
    'rabbitmq/host'                         : value => $rabbit_own_host;
    'rabbitmq/port'                         : value => $rabbit_own_port;
  }

  if $keystone_password {
    murano_config {
      'keystone_authtoken/auth_uri'           : value => $keystone_uri;
      'keystone_authtoken/admin_user'         : value => $keystone_username;
      'keystone_authtoken/admin_tenant_name'  : value => $keystone_tenant;
      'keystone_authtoken/admin_password'     : value => $keystone_password;
      'keystone_authtoken/signing_dir'        : value => $keystone_signing_dir;
      'keystone_authtoken/identity_uri'       : value => $identity_uri;
    }
  }

  exec { 'murano-dbmanage':
    command     => $::murano::params::dbmanage_command,
    path        => '/usr/bin',
    user        => 'murano',
    refreshonly => true,
    subscribe   => [Package['murano-api'], Murano_config['database/connection']],
    logoutput   => on_failure,
  }
}
