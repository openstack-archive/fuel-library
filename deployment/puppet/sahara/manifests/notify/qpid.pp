# == Class: sahara::notify::qpid
#
#  Qpid broker configuration for Sahara
#
# === Parameters
#
# [*durable_queues*]
#   (Optional) Use durable queues in broker.
#   Defaults to false.
#
# [*qpid_hostname*]
#   (Optional) IP or hostname of the qpid server.
#   Defaults to '127.0.0.1'.
#
# [*qpid_port*]
#   (Optional) Port of the qpid server.
#   Defaults to 5672.
#
# [*qpid_username*]
#   (Optional) User to connect to the qpid server.
#   Defaults to 'guest'.
#
# [*qpid_password*]
#   (Optional) Password to connect to the qpid server.
#   Defaults to 'guest'.
#
# [*qpid_sasl_mechanisms*]
#   (Optional) String of SASL mechanisms to use.
#   Defaults to ''.
#
# [*qpid_heartbeat*]
#   (Optional) Seconds between connection keepalive heartbeats.
#   Defaults to 60.
#
# [*qpid_protocol*]
#   (Optional) Protocol to use for qpid (tcp/ssl).
#   Defaults to tcp.
#
# [*qpid_tcp_nodelay*]
#   (Optional) Whether to disable the Nagle algorithm.
#   Defaults to true.
#
# [*qpid_receiver_capacity*]
#   (Optional) Number of prefetched messages to hold.
#   Defaults to 1.
#
# [*qpid_topology_version*]
#   (Optional) Version of qpid toplogy to use.
#   Defaults to 2.
#
# [*notification_topics*]
#   (Optional) Topic to use for notifications.
#   Defaults to 'notifications'.
#
# [*control_exchange*]
#   (Optional) The default exchange to scope topics.
#   Defaults to 'openstack'.
#
#  [*kombu_ssl_version*]
#    (optional) SSL version to use (valid only if SSL enabled).
#    Valid values are TLSv1, SSLv23 and SSLv3. SSLv2 may be
#    available on some distributions.
#    Defaults to 'TLSv1'
#
# [*kombu_ssl_keyfile*]
#   (Optional) SSL key file (valid only if SSL enabled).
#   Defaults to undef.
#
# [*kombu_ssl_certfile*]
#   (Optional) SSL cert file (valid only if SSL enabled).
#   Defaults to undef.
#
# [*kombu_ssl_ca_certs*]
#   (optional) SSL certification authority file (valid only if SSL enabled).
#   Defaults to undef.
#
# [*kombu_reconnect_delay*]
#   (Optional) Backoff on cancel notification (valid only if SSL enabled).
#   Defaults to '1.0'; floating-point value.
#
class sahara::notify::qpid(
  $durable_queues         = false,
  $qpid_hostname          = 'localhost',
  $qpid_port              = 5672,
  $qpid_username          = 'guest',
  $qpid_password          = 'guest',
  $qpid_sasl_mechanisms   = '',
  $qpid_heartbeat         = 60,
  $qpid_protocol          = 'tcp',
  $qpid_tcp_nodelay       = true,
  $qpid_receiver_capacity = 1,
  $qpid_topology_version  = 2,
  $notification_topics    = 'notifications',
  $control_exchange       = 'openstack',
  $kombu_ssl_version      = 'TLSv1',
  $kombu_ssl_keyfile      = undef,
  $kombu_ssl_certfile     = undef,
  $kombu_ssl_ca_certs     = undef,
  $kombu_reconnect_delay  = '1.0',
) {
  if $qpid_protocol == 'ssl' {
    if !$kombu_ssl_keyfile {
      fail('kombu_ssl_keyfile must be set when using SSL in qpid')
    }
    if !$kombu_ssl_certfile {
      fail('kombu_ssl_certfile must be set when using SSL in qpid')
    }
    if !$kombu_ssl_ca_certs {
      fail('kombu_ca_certs must be set when using SSL in qpid')
    }
    sahara_config {
      'DEFAULT/kombu_ssl_version': value => $kombu_ssl_version;
      'DEFAULT/kombu_ssl_keyfile': value => $kombu_ssl_keyfile;
      'DEFAULT/kombu_ssl_certfile': value => $kombu_ssl_certfile;
      'DEFAULT/kombu_ssl_ca_certs': value => $kombu_ssl_ca_certs;
      'DEFAULT/kombu_reconnect_delay': value => $kombu_reconnect_delay;
    }
  } elsif $qpid_protocol == 'tcp' {
    sahara_config {
      'DEFAULT/kombu_ssl_version': ensure => absent;
      'DEFAULT/kombu_ssl_keyfile': ensure => absent;
      'DEFAULT/kombu_ssl_certfile': ensure => absent;
      'DEFAULT/kombu_ssl_ca_certs': ensure => absent;
      'DEFAULT/kombu_reconnect_delay': ensure => absent;
    }
  } else {
    fail("valid qpid_protocol settings are 'tcp' and 'ssl' only")
  }

  sahara_config {
    'DEFAULT/rpc_backend': value => 'qpid';
    'DEFAULT/qpid_hosts': value => '$qpid_hostname:$qpid_port';

    'DEFAULT/amqp_durable_queues': value => $durable_queues;
    'DEFAULT/qpid_hostname': value => $qpid_hostname;
    'DEFAULT/qpid_port': value => $qpid_port;
    'DEFAULT/qpid_username': value => $qpid_username;
    'DEFAULT/qpid_password':
      value => $qpid_password,
      secret => true;
    'DEFAULT/qpid_sasl_mechanisms': value => $qpid_sasl_mechanisms;
    'DEFAULT/qpid_heartbeat': value => $qpid_heartbeat;
    'DEFAULT/qpid_protocol': value => $qpid_protocol;
    'DEFAULT/qpid_tcp_nodelay': value => $qpid_tcp_nodelay;
    'DEFAULT/qpid_receiver_capacity': value => $qpid_receiver_capacity;
    'DEFAULT/qpid_topology_version': value => $qpid_topology_version;
    'DEFAULT/notification_topics': value => $notification_topics;
    'DEFAULT/control_exchange': value => $control_exchange;
  }
}
