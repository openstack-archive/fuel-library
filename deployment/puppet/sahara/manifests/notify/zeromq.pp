# == Class: sahara::notify::zeromq
#
#  Zeromq broker configuration for Sahara
#  Deprecated class
#
# === Parameters
#
# [*zeromq_bind_address*]
#   (Optional) Bind address; wildcard, ethernet, or ip address.
#   Defaults to '*'.
#
# [*zeromq_port*]
#   (Optional) Receiver listening port.
#   Defaults to 9501.
#
# [*zeromq_contexts*]
#   (Optional) Number of contexsts for zeromq.
#   Defaults to 1.
#
# [*zeromq_topic_backlog*]
#   (Optional) Number of incoming messages to buffer.
#   Defaults to 'None'.
#
# [*zeromq_ipc_dir*]
#   (Optional) Directory for zeromq IPC.
#   Defaults to '/var/run/openstack'.
#
# [*zeromq_host*]
#   (Optional) Name of the current node: hostname, FQDN, or IP.
#   Defaults to 'sahara'.
#
# [*cast_timeout*]
#   (Optional) TTL for zeromq messages.
#   Defaults to 30.
#
class sahara::notify::zeromq(
  $zeromq_bind_address    = '*',
  $zeromq_port            = 9501,
  $zeromq_contexts        = 1,
  $zeromq_topic_backlog   = 'None',
  $zeromq_ipc_dir         = '/var/run/openstack',
  $zeromq_host            = 'sahara',
  $cast_timeout           = 30,
) {

  warning('This class is deprecated. Use sahara::init for configuration rpc options instead')

  sahara_config {
    'DEFAULT/rpc_backend':           value => 'zmq';
    'DEFAULT/rpc_zmq_bind_address':  value => $zeromq_bind_address;
    'DEFAULT/rpc_zmq_port':          value => $zeromq_port;
    'DEFAULT/rpc_zmq_contexts':      value => $zeromq_contexts;
    'DEFAULT/rpc_zmq_topic_backlog': value => $zeromq_topic_backlog;
    'DEFAULT/rpc_zmq_ipc_dir':       value => $zeromq_ipc_dir;
    'DEFAULT/rpc_zmq_host':          value => $zeromq_host;
    'DEFAULT/rpc_cast_timeout':      value => $cast_timeout;
  }
}
