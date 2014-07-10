# == Class: neutron
#
# Installs the neutron package and configures
# /etc/neutron/neutron.conf
#
# === Parameters:
#
# [*enabled*]
#   (required) Whether or not to enable the neutron service
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
# [*bind_host*]
#   (optional) The IP/interface to bind to
#   Defaults to 0.0.0.0 (all interfaces)
#
# [*bind_port*]
#   (optional) The port to use
#   Defaults to 9696
#
# [*core_plugin*]
#   (optional) Neutron plugin provider
#   Defaults to openvswitch
#   Could be bigswitch, brocade, cisco, embrane, hyperv, linuxbridge, midonet, ml2, mlnx, nec, nicira, plumgrid, ryu
#
# [*service_plugins*]
#   (optional) Advanced service modules.
#   Could be an array that can have these elements:
#   router, firewall, lbaas, vpnaas, metering
#   Defaults to empty
#
# [*auth_strategy*]
#   (optional) How to authenticate
#   Defaults to 'keystone'. 'noauth' is the only other valid option
#
# [*base_mac*]
#   (optional) The MAC address pattern to use.
#   Defaults to fa:16:3e:00:00:00
#
# [*mac_generation_retries*]
#   (optional) How many times to try to generate a unique mac
#   Defaults to 16
#
# [*dhcp_lease_duration*]
#   (optional) DHCP lease
#   Defaults to 86400 seconds
#
# [*dhcp_agents_per_network*]
#   (optional) Number of DHCP agents scheduled to host a network.
#   This enables redundant DHCP agents for configured networks.
#   Defaults to 1
#
# [*allow_bulk*]
#   (optional) Enable bulk crud operations
#   Defaults to true
#
# [*allow_pagination*]
#   (optional) Enable pagination
#   Defaults to false
#
# [*allow_sorting*]
#   (optional) Enable sorting
#   Defaults to false
#
# [*allow_overlapping_ips*]
#   (optional) Enables network namespaces
#   Defaults to false
#
# [*report_interval*]
#   (optional) Seconds between nodes reporting state to server; should be less than
#   agent_down_time, best if it is half or less than agent_down_time.
#   agent_down_time is a config for neutron-server, set by class neutron::server
#   report_interval is a config for neutron agents, set by class neutron
#   Defaults to: 30
#
# [*control_exchange*]
#   (optional) What RPC queue/exchange to use
#   Defaults to neutron

# [*rpc_backend*]
#   (optional) what rpc/queuing service to use
#   Defaults to impl_kombu (rabbitmq)
#
# [*rabbit_password*]
# [*rabbit_host*]
# [*rabbit_port*]
# [*rabbit_user*]
#   (optional) Various rabbitmq settings
#
# [*rabbit_hosts*]
#   (optional) array of rabbitmq servers for HA.
#   A single IP address, such as a VIP, can be used for load-balancing
#   multiple RabbitMQ Brokers.
#   Defaults to false
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
#   Defaults to 'SSLv3'
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
# [*use_ssl*]
#   (optinal) Enable SSL on the API server
#   Defaults to false, not set
#
# [*cert_file*]
#   (optinal) certificate file to use when starting api server securely
#   defaults to false, not set
#
# [*key_file*]
#   (optional) Private key file to use when starting API server securely
#   Defaults to false, not set
#
# [*ca_file*]
#   (optional) CA certificate file to use to verify connecting clients
#   Defaults to false, not set
#
# [*use_syslog*]
#   (optional) Use syslog for logging
#   Defaults to false
#
# [*log_facility*]
#   (optional) Syslog facility to receive log lines
#   Defaults to LOG_USER
#
# [*log_file*]
#   (optional) Where to log
#   Defaults to false
#
# [*log_dir*]
#   (optional) Directory where logs should be stored
#   If set to boolean false, it will not log to any directory
#   Defaults to /var/log/neutron
#
class neutron (
  $enabled                     = true,
  $package_ensure              = 'present',
  $verbose                     = false,
  $debug                       = false,
  $bind_host                   = '0.0.0.0',
  $bind_port                   = '9696',
  $core_plugin                 = 'openvswitch',
  $service_plugins             = undef,
  $auth_strategy               = 'keystone',
  $base_mac                    = 'fa:16:3e:00:00:00',
  $mac_generation_retries      = 16,
  $dhcp_lease_duration         = 86400,
  $dhcp_agents_per_network     = 1,
  $allow_bulk                  = true,
  $allow_pagination            = false,
  $allow_sorting               = false,
  $allow_overlapping_ips       = false,
  $root_helper                 = 'sudo neutron-rootwrap /etc/neutron/rootwrap.conf',
  $report_interval             = '30',
  $control_exchange            = 'neutron',
  $rpc_backend                 = 'neutron.openstack.common.rpc.impl_kombu',
  $rabbit_password             = false,
  $rabbit_host                 = 'localhost',
  $rabbit_hosts                = false,
  $rabbit_port                 = '5672',
  $rabbit_user                 = 'guest',
  $rabbit_virtual_host         = '/',
  $rabbit_use_ssl              = false,
  $kombu_ssl_ca_certs          = undef,
  $kombu_ssl_certfile          = undef,
  $kombu_ssl_keyfile           = undef,
  $kombu_ssl_version           = 'SSLv3',
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
  $use_ssl                     = false,
  $cert_file                   = false,
  $key_file                    = false,
  $ca_file                     = false,
  $use_syslog                  = false,
  $log_facility                = 'LOG_USER',
  $log_file                    = false,
  $log_dir                     = '/var/log/neutron',
) {

  include neutron::params

  Package['neutron'] -> Neutron_config<||>

  if $use_ssl {
    if !$cert_file {
      fail('The cert_file parameter is required when use_ssl is set to true')
    }
    if !$ca_file {
      fail('The ca_file parameter is required when use_ssl is set to true')
    }
    if !$key_file {
      fail('The key_file parameter is required when use_ssl is set to true')
    }
  }

  if $rabbit_use_ssl {
    if !$kombu_ssl_ca_certs {
      fail('The kombu_ssl_ca_certs parameter is required when rabbit_use_ssl is set to true')
    }
    if !$kombu_ssl_certfile {
      fail('The kombu_ssl_certfile parameter is required when rabbit_use_ssl is set to true')
    }
    if !$kombu_ssl_keyfile {
      fail('The kombu_ssl_keyfile parameter is required when rabbit_use_ssl is set to true')
    }
  }

  File {
    require => Package['neutron'],
    owner   => 'root',
    group   => 'neutron',
    mode    => '0640',
  }

  file { '/etc/neutron':
    ensure  => directory,
    mode    => '0750',
  }

  file { '/etc/neutron/neutron.conf': }

  package { 'neutron':
    ensure => $package_ensure,
    name   => $::neutron::params::package_name,
  }

  neutron_config {
    'DEFAULT/verbose':                 value => $verbose;
    'DEFAULT/debug':                   value => $debug;
    'DEFAULT/bind_host':               value => $bind_host;
    'DEFAULT/bind_port':               value => $bind_port;
    'DEFAULT/auth_strategy':           value => $auth_strategy;
    'DEFAULT/core_plugin':             value => $core_plugin;
    'DEFAULT/base_mac':                value => $base_mac;
    'DEFAULT/mac_generation_retries':  value => $mac_generation_retries;
    'DEFAULT/dhcp_lease_duration':     value => $dhcp_lease_duration;
    'DEFAULT/dhcp_agents_per_network': value => $dhcp_agents_per_network;
    'DEFAULT/allow_bulk':              value => $allow_bulk;
    'DEFAULT/allow_pagination':        value => $allow_pagination;
    'DEFAULT/allow_sorting':           value => $allow_sorting;
    'DEFAULT/allow_overlapping_ips':   value => $allow_overlapping_ips;
    'DEFAULT/control_exchange':        value => $control_exchange;
    'DEFAULT/rpc_backend':             value => $rpc_backend;
    'agent/root_helper':               value => $root_helper;
    'agent/report_interval':           value => $report_interval;
  }

  if $log_file {
    neutron_config {
      'DEFAULT/log_file': value => $log_file;
      'DEFAULT/log_dir':  value => $log_dir;
    }
  } else {
    if $log_dir {
      neutron_config {
        'DEFAULT/log_dir':  value  => $log_dir;
        'DEFAULT/log_file': ensure => absent;
      }
    } else {
      neutron_config {
        'DEFAULT/log_dir':  ensure => absent;
        'DEFAULT/log_file': ensure => absent;
      }
    }
  }

  if $service_plugins {
    if is_array($service_plugins) {
      neutron_config { 'DEFAULT/service_plugins': value => join($service_plugins, ',') }
    } else {
      fail('service_plugins should be an array.')
    }
  }

  if $rpc_backend == 'neutron.openstack.common.rpc.impl_kombu' {
    if ! $rabbit_password {
      fail('When rpc_backend is rabbitmq, you must set rabbit password')
    }
    if $rabbit_hosts {
      neutron_config { 'DEFAULT/rabbit_hosts':     value  => join($rabbit_hosts, ',') }
      neutron_config { 'DEFAULT/rabbit_ha_queues': value  => true }
    } else  {
      neutron_config { 'DEFAULT/rabbit_host':      value => $rabbit_host }
      neutron_config { 'DEFAULT/rabbit_port':      value => $rabbit_port }
      neutron_config { 'DEFAULT/rabbit_hosts':     value => "${rabbit_host}:${rabbit_port}" }
      neutron_config { 'DEFAULT/rabbit_ha_queues': value => false }
    }

    neutron_config {
      'DEFAULT/rabbit_userid':       value => $rabbit_user;
      'DEFAULT/rabbit_password':     value => $rabbit_password;
      'DEFAULT/rabbit_virtual_host': value => $rabbit_virtual_host;
      'DEFAULT/rabbit_use_ssl':      value => $rabbit_use_ssl;
    }

    if $rabbit_use_ssl {
      neutron_config {
        'DEFAULT/kombu_ssl_ca_certs': value => $kombu_ssl_ca_certs;
        'DEFAULT/kombu_ssl_certfile': value => $kombu_ssl_certfile;
        'DEFAULT/kombu_ssl_keyfile':  value => $kombu_ssl_keyfile;
        'DEFAULT/kombu_ssl_version':  value => $kombu_ssl_version;
      }
    } else {
      neutron_config {
        'DEFAULT/kombu_ssl_ca_certs': ensure => absent;
        'DEFAULT/kombu_ssl_certfile': ensure => absent;
        'DEFAULT/kombu_ssl_keyfile':  ensure => absent;
        'DEFAULT/kombu_ssl_version':  ensure => absent;
      }
    }

  }

  if $rpc_backend == 'neutron.openstack.common.rpc.impl_qpid' {
    neutron_config {
      'DEFAULT/qpid_hostname':               value => $qpid_hostname;
      'DEFAULT/qpid_port':                   value => $qpid_port;
      'DEFAULT/qpid_username':               value => $qpid_username;
      'DEFAULT/qpid_password':               value => $qpid_password;
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

  # SSL Options
  neutron_config { 'DEFAULT/use_ssl' : value => $use_ssl; }
  if $use_ssl {
    neutron_config {
      'DEFAULT/ssl_cert_file' : value => $cert_file;
      'DEFAULT/ssl_key_file'  : value => $key_file;
      'DEFAULT/ssl_ca_file'   : value => $ca_file;
    }
  } else {
    neutron_config {
      'DEFAULT/ssl_cert_file': ensure => absent;
      'DEFAULT/ssl_key_file':  ensure => absent;
      'DEFAULT/ssl_ca_file':   ensure => absent;
    }
  }

  if $use_syslog {
    neutron_config {
      'DEFAULT/use_syslog':           value => true;
      'DEFAULT/syslog_log_facility':  value => $log_facility;
    }
  } else {
    neutron_config {
      'DEFAULT/use_syslog':           value => false;
    }
  }
}
