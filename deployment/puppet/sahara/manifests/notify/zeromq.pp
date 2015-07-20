# == Class: sahara::notify::zeromq
#
#  Zeromq broker configuration for Sahara
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
class sahara::notify::zeromq(
  $zeromq_bind_address    = '*',
  $zeromq_port            = 9501,
  $zeromq_contexts        = 1,
  $zeromq_topic_backlog   = 'None',
  $zeromq_ipc_dir         = '/var/run/openstack',
  $zeromq_host            = 'sahara',
  $cast_timeout           = 30,
  $kombu_ssl_version      = 'TLSv1',
  $kombu_ssl_keyfile      = undef,
  $kombu_ssl_certfile     = undef,
  $kombu_ssl_ca_certs     = undef,
  $kombu_reconnect_delay  = '1.0',
) {
  if $kombu_ssl_keyfile or $kombu_ssl_certfile or $kombu_ssl_ca_certs {
    if !$kombu_ssl_keyfile {
      fail('kombu_ssl_keyfile must be set when using SSL in zeromq')
    }
    if !$kombu_ssl_certfile {
      fail('kombu_ssl_certfile must be set when using SSL in zeromq')
    }
    if !$kombu_ssl_ca_certs {
      fail('kombu_ca_certs must be set when using SSL in zeromq')
    }
    sahara_config {
      'DEFAULT/kombu_ssl_version': value => $kombu_ssl_version;
      'DEFAULT/kombu_ssl_keyfile': value => $kombu_ssl_keyfile;
      'DEFAULT/kombu_ssl_certfile': value => $kombu_ssl_certfile;
      'DEFAULT/kombu_ssl_ca_certs': value => $kombu_ssl_ca_certs;
      'DEFAULT/kombu_reconnect_delay': value => $kombu_reconnect_delay;
    }
  } else {
    sahara_config {
      'DEFAULT/kombu_ssl_version': ensure => absent;
      'DEFAULT/kombu_ssl_keyfile': ensure => absent;
      'DEFAULT/kombu_ssl_certfile': ensure => absent;
      'DEFAULT/kombu_ssl_ca_certs': ensure => absent;
      'DEFAULT/kombu_reconnect_delay': ensure => absent;
    }
  }

  sahara_config {
    'DEFAULT/rpc_backend': value => 'zmq';
    'DEFAULT/rpc_zmq_bind_address': value => $zeromq_bind_address;
    'DEFAULT/rpc_zmq_port': value => $zeromq_port;
    'DEFAULT/rpc_zmq_contexts': value => $zeromq_contexts;
    'DEFAULT/rpc_zmq_topic_backlog': value => $zeromq_topic_backlog;
    'DEFAULT/rpc_zmq_ipc_dir': value => $zeromq_ipc_dir;
    'DEFAULT/rpc_zmq_host': value => $zeromq_host;
    'DEFAULT/rpc_cast_timeout': value => $cast_timeout;
  }
}
