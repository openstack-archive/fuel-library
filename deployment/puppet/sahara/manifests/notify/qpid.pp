# == Class: sahara::notify::qpid
#
#  Qpid broker configuration for Sahara
#  Deprecated class
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
) {

  warning('This class is deprecated. Use sahara::init for configuration rpc options instead')
  warning('This class is deprecated. Use sahara::notify for configuration ceilometer notifications instead')

  sahara_config {
    'DEFAULT/rpc_backend':                        value => 'qpid';
    'oslo_messaging_qpid/qpid_hosts':             value => '$qpid_hostname:$qpid_port';

    'oslo_messaging_qpid/amqp_durable_queues':    value => $durable_queues;
    'oslo_messaging_qpid/qpid_hostname':          value => $qpid_hostname;
    'oslo_messaging_qpid/qpid_port':              value => $qpid_port;
    'oslo_messaging_qpid/qpid_username':          value => $qpid_username;
    'oslo_messaging_qpid/qpid_password':
      value => $qpid_password,
      secret => true;
    'oslo_messaging_qpid/qpid_sasl_mechanisms':   value => $qpid_sasl_mechanisms;
    'oslo_messaging_qpid/qpid_heartbeat':         value => $qpid_heartbeat;
    'oslo_messaging_qpid/qpid_protocol':          value => $qpid_protocol;
    'oslo_messaging_qpid/qpid_tcp_nodelay':       value => $qpid_tcp_nodelay;
    'oslo_messaging_qpid/qpid_receiver_capacity': value => $qpid_receiver_capacity;
    'oslo_messaging_qpid/qpid_topology_version':  value => $qpid_topology_version;
    'DEFAULT/notification_topics':                value => $notification_topics;
    'DEFAULT/control_exchange':                   value => $control_exchange;
  }
}
