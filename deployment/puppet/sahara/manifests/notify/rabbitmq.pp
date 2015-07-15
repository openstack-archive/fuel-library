# == Class: sahara::notify::rabbitmq
#
#  RabbitMQ broker configuration for Sahara
#
# === Parameters
#
# [*durable_queues*]
#   (Optional) Use durable queues in broker.
#   Defaults to false.
#
# [*rabbit_host*]
#   (Optional) IP or hostname of the rabbit server.
#   Defaults to '127.0.0.1'.
#
# [*rabbit_port*]
#   (Optional) Port of the rabbit server.
#   Defaults to 5672.
#
# [*rabbit_hosts*]
#   (Optional) IP or hostname of the rabbits servers.
#   comma separated array (ex: ['1.0.0.10:5672','1.0.0.11:5672'])
#   Defaults to false.
#
# [*rabbit_use_ssl*]
#   (Optional) Connect over SSL for RabbitMQ.
#   Defaults to false.
#
# [*rabbit_userid*]
#   (Optional) User to connect to the rabbit server.
#   Defaults to 'guest'.
#
# [*rabbit_password*]
#   (Optional) Password to connect to the rabbit server.
#   Defaults to 'guest'.
#
# [*rabbit_login_method*]
#   (Optional) Method to auth with the rabbit server.
#   Defaults to 'AMQPLAIN'.
#
# [*rabbit_virtual_host*]
#   (Optional) Virtual host to use.
#   Defaults to '/'.
#
# [*rabbit_retry_interval*]
#   (Optional) Reconnection attempt frequency for rabbit.
#   Defaults to 1.
#
# [*rabbit_retry_backoff*]
#   (Optional) Backoff between reconnection attempts for rabbit.
#   Defaults to 2.
#
# [*rabbit_max_retries*]
#   (Optional) Number of times to retry (0 == no limit).
#   Defaults to 0.
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
#   (Optional) SSL certification authority file (valid only if SSL enabled).
#   Defaults to undef
#
# [*kombu_reconnect_delay*]
#   (Optional) Backoff on cancel notification (valid only if SSL enabled).
#   Defaults to '1.0'; floating-point value.
#
class sahara::notify::rabbitmq(
  $durable_queues        = false,
  $rabbit_host           = 'localhost',
  $rabbit_hosts          = false,
  $rabbit_port           = 5672,
  $rabbit_use_ssl        = false,
  $rabbit_userid         = 'guest',
  $rabbit_password       = 'guest',
  $rabbit_login_method   = 'AMQPLAIN',
  $rabbit_virtual_host   = '/',
  $rabbit_retry_interval = 1,
  $rabbit_retry_backoff  = 2,
  $rabbit_max_retries    = 0,
  $notification_topics   = 'notifications',
  $control_exchange      = 'openstack',
  $kombu_ssl_version     = 'TLSv1',
  $kombu_ssl_keyfile     = undef,
  $kombu_ssl_certfile    = undef,
  $kombu_ssl_ca_certs    = undef,
  $kombu_reconnect_delay = '1.0',
) {
  if $rabbit_use_ssl {

    if $kombu_ssl_ca_certs {
      sahara_config { 'oslo_messaging_rabbit/kombu_ssl_ca_certs': value => $kombu_ssl_ca_certs; }
    } else {
      sahara_config { 'oslo_messaging_rabbit/kombu_ssl_ca_certs': ensure => absent; }
    }

    if $kombu_ssl_certfile or $kombu_ssl_keyfile {
      sahara_config {
        'oslo_messaging_rabbit/kombu_ssl_certfile': value => $kombu_ssl_certfile;
        'oslo_messaging_rabbit/kombu_ssl_keyfile':  value => $kombu_ssl_keyfile;
      }
    } else {
      sahara_config {
        'oslo_messaging_rabbit/kombu_ssl_certfile': ensure => absent;
        'oslo_messaging_rabbit/kombu_ssl_keyfile':  ensure => absent;
      }
    }

    if $kombu_ssl_version {
      sahara_config { 'oslo_messaging_rabbit/kombu_ssl_version':  value => $kombu_ssl_version; }
    } else {
      sahara_config { 'oslo_messaging_rabbit/kombu_ssl_version':  ensure => absent; }
    }

  } else {
    sahara_config {
      'oslo_messaging_rabbit/kombu_ssl_ca_certs': ensure => absent;
      'oslo_messaging_rabbit/kombu_ssl_certfile': ensure => absent;
      'oslo_messaging_rabbit/kombu_ssl_keyfile':  ensure => absent;
      'oslo_messaging_rabbit/kombu_ssl_version':  ensure => absent;
    }
  }

  if $rabbit_hosts {
    sahara_config {
      'oslo_messaging_rabbit/rabbit_hosts':     value => join($rabbit_hosts, ',');
      'oslo_messaging_rabbit/rabbit_ha_queues': value => true;
    }
  } else {
    sahara_config {
      'oslo_messaging_rabbit/rabbit_host':      value => $rabbit_host;
      'oslo_messaging_rabbit/rabbit_port':      value => $rabbit_port;
      'oslo_messaging_rabbit/rabbit_ha_queues': value => false;
      'oslo_messaging_rabbit/rabbit_hosts':     value => "${rabbit_host}:${rabbit_port}";
    }
  }

  sahara_config {
    'oslo_messaging_rabbit/rpc_backend': value => 'rabbit';
    'DEFAULT/amqp_durable_queues': value => $durable_queues;
    'oslo_messaging_rabbit/rabbit_use_ssl': value => $rabbit_use_ssl;
    'oslo_messaging_rabbit/rabbit_userid': value => $rabbit_userid;
    'oslo_messaging_rabbit/rabbit_password':
      value => $rabbit_password,
      secret => true;
    'oslo_messaging_rabbit/rabbit_login_method': value => $rabbit_login_method;
    'oslo_messaging_rabbit/rabbit_virtual_host': value => $rabbit_virtual_host;
    'oslo_messaging_rabbit/rabbit_retry_interval': value => $rabbit_retry_interval;
    'oslo_messaging_rabbit/rabbit_retry_backoff': value => $rabbit_retry_backoff;
    'oslo_messaging_rabbit/rabbit_max_retries': value => $rabbit_max_retries;
    'DEFAULT/notification_topics': value => $notification_topics;
    'DEFAULT/control_exchange': value => $control_exchange;
    'oslo_messaging_rabbit/kombu_reconnect_delay': value => $kombu_reconnect_delay;
  }
}
