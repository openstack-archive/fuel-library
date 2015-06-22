#
# Copyright (C) 2013 eNovance SAS <licensing@enovance.com>
#
# Author: Emilien Macchi <emilien.macchi@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: ironic
#
# Installs the ironic package and configures /etc/ironic/ironic.conf
#
# === Parameters:
#
# [*enabled*]
#   (required) Whether or not to enable the ironic service
#   true/false
#
# [*package_ensure*]
#   (optional) The state of the package
#   Defaults to 'present'
#
# [*verbose*]
#   (optional) Verbose logging
#   Defaults to False
#
# [*debug*]
#   (optional) Print debug messages in the logs
#   Defaults to False
#
# [*auth_strategy*]
#   (optional) Default protocol to use when connecting to glance
#   Defaults to 'keystone'. 'https' is the only other valid option for SSL
#
# [*enabled_drivers*]
#  (optional) Array of drivers to load during service
#  initialization.
#  Defaults to ['pxe_ipmitool'].
#
# [*control_exchange*]
#   (optional) What RPC queue/exchange to use
#   Defaults to openstack
#
# [*rpc_backend*]
#   (optional) what rpc/queuing service to use
#   Defaults to impl_kombu (rabbitmq)
#
# [*rabbit_host*]
#   (Optional) IP or hostname of the rabbit server.
#   Defaults to 'localhost'
#
# [*rabbit_port*]
#   (Optional) Port of the rabbit server.
#   Defaults to 5672.
#
# [*rabbit_hosts*]
#   (Optional) Array of host:port (used with HA queues).
#   If defined, will remove rabbit_host & rabbit_port parameters from config
#   Defaults to undef.
#
# [*rabbit_user*]
#   (Optional) User to connect to the rabbit server.
#   Defaults to undef.
#   Deprecated, use rabbit_userid instead.
#
# [*rabbit_userid*]
#   (Optional) User to connect to the rabbit server.
#   Defaults to 'guest'
#
# [*rabbit_password*]
#   (Optional) Password to connect to the rabbit_server.
#   Defaults to empty.
#
# [*rabbit_virtual_host*]
#   (Optional) Virtual_host to use.
#   Defaults to '/'
#
# [*rabbit_use_ssl*]
#   (optional) Connect over SSL for RabbitMQ
#   Defaults to false
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
#   Use durable queues in amqp.
#   (Optional) Defaults to false.
#
# [*rabbit_virtual_host*]
#   (optional) Various rabbitmq settings
#
# [*rabbit_hosts*]
#   (optional) array of rabbitmq servers for HA.
#   A single IP address, such as a VIP, can be used for load-balancing
#   multiple RabbitMQ Brokers.
#   Defaults to false
#
# [*qpid_hostname*]
# [*qpid_port*]
# [*qpid_username*]
# [*qpid_password*]
# [*qpid_heartbeat*]
# [*qpid_protocol*]
# [*qpid_tcp_nodelay*]
# [*qpid_reconnect*]
# [*qpid_reconnect_timeout*]
# [*qpid_reconnect_limit*]
# [*qpid_reconnect_interval*]
# [*qpid_reconnect_interval_min*]
# [*qpid_reconnect_interval_max*]
#   (optional) various QPID options
#
# [*use_syslog*]
#   (optional) Use syslog for logging
#   Defaults to false
#
# [*log_facility*]
#   (optional) Syslog facility to receive log lines
#   Defaults to LOG_USER
#
# [*database_connection*]
#   (optional) Connection url for the ironic database.
#   Defaults to: sqlite:////var/lib/ironic/ironic.sqlite
#
# [*database_max_retries*]
#   (optional) Database reconnection retry times.
#   Defaults to: 10
#
# [*database_idle_timeout*]
#   (optional) Timeout before idle db connections are reaped.
#   Defaults to: 3600
#
# [*database_retry_interval*]
#   (optional) Database reconnection interval in seconds.
#   Defaults to: 10
#
# [*glance_api_servers*]
#   (optional) A list of the glance api servers available to ironic.
#   Should be an array with [hostname|ip]:port
#   Defaults to undef
#
# [*glance_num_retries*]
#   (optional) Number retries when downloading an image from glance.
#   Defaults to 0
#
# [*glance_api_insecure*]
#   (optional) Allow to perform insecure SSL (https) requests to glance.
#   Defaults to false
#

class ironic (
  $enabled                     = true,
  $package_ensure              = 'present',
  $verbose                     = false,
  $debug                       = false,
  $auth_strategy               = 'keystone',
  $enabled_drivers             = ['pxe_ipmitool'],
  $control_exchange            = 'openstack',
  $rpc_backend                 = 'ironic.openstack.common.rpc.impl_kombu',
  $rabbit_hosts                = false,
  $rabbit_virtual_host         = '/',
  $rabbit_host                 = 'localhost',
  $rabbit_port                 = 5672,
  $rabbit_hosts                = false,
  $rabbit_virtual_host         = '/',
  $rabbit_userid               = 'guest',
  $rabbit_password             = false,
  $rabbit_use_ssl              = false,
  $kombu_ssl_ca_certs          = undef,
  $kombu_ssl_certfile          = undef,
  $kombu_ssl_keyfile           = undef,
  $kombu_ssl_version           = 'TLSv1',
  $amqp_durable_queues         = false,
  $qpid_hostname               = 'localhost',
  $qpid_port                   = '5672',
  $qpid_username               = 'guest',
  $qpid_password               = 'guest',
  $qpid_heartbeat              = 60,
  $qpid_protocol               = 'tcp',
  $qpid_tcp_nodelay            = true,
  $qpid_reconnect              = true,
  $qpid_reconnect_timeout      = 0,
  $qpid_reconnect_limit        = 0,
  $qpid_reconnect_interval_min = 0,
  $qpid_reconnect_interval_max = 0,
  $qpid_reconnect_interval     = 0,
  $use_syslog                  = false,
  $log_facility                = 'LOG_USER',
  $database_connection         = 'sqlite:////var/lib/ironic/ovs.sqlite',
  $database_max_retries        = '10',
  $database_idle_timeout       = '3600',
  $database_reconnect_interval = '10',
  $database_retry_interval     = '10',
  $glance_api_servers          = undef,
  $glance_num_retries          = '0',
  $glance_api_insecure         = false,
  # DEPRECATED PARAMETERS
  $rabbit_user                 = undef,
) {

  include ::ironic::params

  if $rabbit_user {
    warning('The rabbit_user parameter is deprecated. Please use rabbit_userid instead.')
    $rabbit_user_real = $rabbit_user
  } else {
    $rabbit_user_real = $rabbit_userid
  }

  Package['ironic-common'] -> Ironic_config<||>

  file { '/etc/ironic':
    ensure  => directory,
    require => Package['ironic-common'],
    group   => 'ironic',
  }

  file { '/etc/ironic/ironic.conf':
    require => Package['ironic-common'],
    group   => 'ironic',
  }

  package { 'ironic-common':
    ensure => $package_ensure,
    name   => $::ironic::params::common_package_name,
    tag    => 'openstack',
    notify => Exec['ironic-dbsync'],
  }

  validate_re($database_connection, '(sqlite|mysql|postgresql):\/\/(\S+:\S+@\S+\/\S+)?')
  validate_array($enabled_drivers)

  case $database_connection {
    /mysql:\/\/\S+:\S+@\S+\/\S+/: {
      $database_backend_package = false
      require 'mysql::bindings'
      require 'mysql::bindings::python'
    }
    /postgresql:\/\/\S+:\S+@\S+\/\S+/: {
      $database_backend_package = 'python-psycopg2'
    }
    /sqlite:\/\//: {
      $database_backend_package = 'python-pysqlite2'
    }
    default: {
      fail("Invalid database connection: ${database_connection}")
    }
  }

  if $database_backend_package and !defined(Package[$database_backend_package]) {
    package { 'ironic-database-backend':
      ensure => present,
      name   => $database_backend_package,
      tag    => 'openstack',
    }
  }

  if is_array($glance_api_servers) {
    ironic_config {
      'glance/glance_api_servers': value => join($glance_api_servers, ',');
    }
  } elsif is_string($glance_api_servers) {
    ironic_config {
      'glance/glance_api_servers': value => $glance_api_servers;
    }
  }

  ironic_config {
    'DEFAULT/verbose':                 value => $verbose;
    'DEFAULT/debug':                   value => $debug;
    'DEFAULT/auth_strategy':           value => $auth_strategy;
    'DEFAULT/rpc_backend':             value => $rpc_backend;
    'DEFAULT/enabled_drivers':         value => join($enabled_drivers, ',');
    'database/connection':             value => $database_connection, secret => true;
    'database/idle_timeout':           value => $database_idle_timeout;
    'database/retry_interval':         value => $database_retry_interval;
    'database/max_retries':            value => $database_max_retries;
    'glance/glance_num_retries':       value => $glance_num_retries;
    'glance/glance_api_insecure':      value => $glance_api_insecure;
  }

  Ironic_config['database/connection'] ~> Exec['ironic-dbsync']

  exec { 'ironic-dbsync':
    command     => $::ironic::params::dbsync_command,
    path        => '/usr/bin',
    # Ubuntu packaging is running dbsync command as root during ironic-common
    # postinstall script so when Puppet tries to run dbsync again, it fails
    # because it is run with ironic user.
    # This is a temporary patch until it's changed in Packaging
    # https://bugs.launchpad.net/cloud-archive/+bug/1450942
    user        => 'root',
    refreshonly => true,
    logoutput   => on_failure,
  }

  if $rpc_backend == 'ironic.openstack.common.rpc.impl_kombu' {

    if ! $rabbit_password {
      fail('When rpc_backend is rabbitmq, you must set rabbit password')
    }

    ironic_config {
      'oslo_messaging_rabbit/rabbit_userid':       value => $rabbit_user_real;
      'oslo_messaging_rabbit/rabbit_password':     value => $rabbit_password, secret => true;
      'oslo_messaging_rabbit/rabbit_virtual_host': value => $rabbit_virtual_host;
      'oslo_messaging_rabbit/rabbit_use_ssl':      value => $rabbit_use_ssl;
      'DEFAULT/control_exchange':    value => $control_exchange;
      'DEFAULT/amqp_durable_queues': value => $amqp_durable_queues;
    }

    if $rabbit_hosts {
      ironic_config { 'oslo_messaging_rabbit/rabbit_hosts':     value  => join($rabbit_hosts, ',') }
      ironic_config { 'oslo_messaging_rabbit/rabbit_ha_queues': value  => true }
      ironic_config { 'oslo_messaging_rabbit/rabbit_host':      ensure => absent }
      ironic_config { 'oslo_messaging_rabbit/rabbit_port':      ensure => absent }
    } else  {
      ironic_config { 'oslo_messaging_rabbit/rabbit_host':      value => $rabbit_host }
      ironic_config { 'oslo_messaging_rabbit/rabbit_port':      value => $rabbit_port }
      ironic_config { 'oslo_messaging_rabbit/rabbit_hosts':     value => "${rabbit_host}:${rabbit_port}" }
      ironic_config { 'oslo_messaging_rabbit/rabbit_ha_queues': value => false }
    }

    if $rabbit_use_ssl {
      ironic_config { 'oslo_messaging_rabbit/kombu_ssl_version': value => $kombu_ssl_version }

      if $kombu_ssl_ca_certs {
        ironic_config { 'oslo_messaging_rabbit/kombu_ssl_ca_certs': value => $kombu_ssl_ca_certs }
      } else {
        ironic_config { 'oslo_messaging_rabbit/kombu_ssl_ca_certs': ensure => absent}
      }

      if $kombu_ssl_certfile {
        ironic_config { 'oslo_messaging_rabbit/kombu_ssl_certfile': value => $kombu_ssl_certfile }
      } else {
        ironic_config { 'oslo_messaging_rabbit/kombu_ssl_certfile': ensure => absent}
      }

      if $kombu_ssl_keyfile {
        ironic_config { 'oslo_messaging_rabbit/kombu_ssl_keyfile': value => $kombu_ssl_keyfile }
      } else {
        ironic_config { 'oslo_messaging_rabbit/kombu_ssl_keyfile': ensure => absent}
      }
    } else {
      ironic_config {
        'oslo_messaging_rabbit/kombu_ssl_ca_certs': ensure => absent;
        'oslo_messaging_rabbit/kombu_ssl_certfile': ensure => absent;
        'oslo_messaging_rabbit/kombu_ssl_keyfile':  ensure => absent;
        'oslo_messaging_rabbit/kombu_ssl_version':  ensure => absent;
      }
    }
  }

  if $rpc_backend == 'ironic.openstack.common.rpc.impl_qpid' {
    ironic_config {
      'DEFAULT/qpid_hostname':               value => $qpid_hostname;
      'DEFAULT/qpid_port':                   value => $qpid_port;
      'DEFAULT/qpid_username':               value => $qpid_username;
      'DEFAULT/qpid_password':               value => $qpid_password, secret => true;
      'DEFAULT/qpid_heartbeat':              value => $qpid_heartbeat;
      'DEFAULT/qpid_protocol':               value => $qpid_protocol;
      'DEFAULT/qpid_tcp_nodelay':            value => $qpid_tcp_nodelay;
      'DEFAULT/qpid_reconnect':              value => $qpid_reconnect;
      'DEFAULT/qpid_reconnect_timeout':      value => $qpid_reconnect_timeout;
      'DEFAULT/qpid_reconnect_limit':        value => $qpid_reconnect_limit;
      'DEFAULT/qpid_reconnect_interval_min': value => $qpid_reconnect_interval_min;
      'DEFAULT/qpid_reconnect_interval_max': value => $qpid_reconnect_interval_max;
      'DEFAULT/qpid_reconnect_interval':     value => $qpid_reconnect_interval;
    }
  }

  if $use_syslog {
    ironic_config {
      'DEFAULT/use_syslog':           value => true;
      'DEFAULT/syslog_log_facility':  value => $log_facility;
    }
  } else {
    ironic_config {
      'DEFAULT/use_syslog':           value => false;
    }
  }

}
