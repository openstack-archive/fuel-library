#
# used to configure rabbitmq notifications for glance
#
#  [*rabbit_password*]
#    password to connect to the rabbit_server.
#
#  [*rabbit_userid*]
#    user to connect to the rabbit server. Optional. Defaults to 'guest'
#
#  [*rabbit_host*]
#    ip or hostname of the rabbit server. Optional. Defaults to 'localhost'
#
# [*rabbit_hosts*]
#   (Optional) IP or hostname of the rabbits servers.
#   comma separated array (ex: ['1.0.0.10:5672','1.0.0.11:5672'])
#   Defaults to false.
#
#  [*rabbit_port*]
#    port of the rabbit server. Optional. Defaults to 5672.
#
#  [*rabbit_virtual_host*]
#    virtual_host to use. Optional. Defaults to '/'
#
#  [*rabbit_use_ssl*]
#    (optional) Connect over SSL for RabbitMQ
#    Defaults to false
#
#  [*kombu_ssl_ca_certs*]
#    (optional) SSL certification authority file (valid only if SSL enabled).
#    Defaults to undef
#
#  [*kombu_ssl_certfile*]
#    (optional) SSL cert file (valid only if SSL enabled).
#    Defaults to undef
#
#  [*kombu_ssl_keyfile*]
#    (optional) SSL key file (valid only if SSL enabled).
#    Defaults to undef
#
#  [*kombu_ssl_version*]
#    (optional) SSL version to use (valid only if SSL enabled).
#    Valid values are TLSv1, SSLv23 and SSLv3. SSLv2 may be
#    available on some distributions.
#    Defaults to 'TLSv1'
#
#  [*rabbit_notification_exchange*]
#    Defaults  to 'glance'
#
#  [*rabbit_notification_topic*]
#    Defaults  to 'notifications'
#
#  [*rabbit_durable_queues*]
#    Defaults  to false
#
# [*amqp_durable_queues*]
#   (Optional) Use durable queues in broker.
#   Defaults to false.
#
#  [*notification_driver*]
#    Notification driver to use. Defaults to 'messaging'.

class glance::notify::rabbitmq(
  $rabbit_password,
  $rabbit_userid                = 'guest',
  $rabbit_host                  = 'localhost',
  $rabbit_port                  = '5672',
  $rabbit_hosts                 = false,
  $rabbit_virtual_host          = '/',
  $rabbit_use_ssl               = false,
  $kombu_ssl_ca_certs           = undef,
  $kombu_ssl_certfile           = undef,
  $kombu_ssl_keyfile            = undef,
  $kombu_ssl_version            = 'TLSv1',
  $rabbit_notification_exchange = 'glance',
  $rabbit_notification_topic    = 'notifications',
  $rabbit_durable_queues        = false,
  $amqp_durable_queues          = false,
  $notification_driver          = 'messaging',
) {

  if $rabbit_durable_queues {
    warning('The rabbit_durable_queues parameter is deprecated, use amqp_durable_queues.')
    $amqp_durable_queues_real = $rabbit_durable_queues
  } else {
    $amqp_durable_queues_real = $amqp_durable_queues
  }

  if $rabbit_hosts {
    glance_api_config {
      'oslo_messaging_rabbit/rabbit_hosts':     value => join($rabbit_hosts, ',');
      'oslo_messaging_rabbit/rabbit_ha_queues': value => true
    }
  } else {
    glance_api_config {
      'oslo_messaging_rabbit/rabbit_host':      value => $rabbit_host;
      'oslo_messaging_rabbit/rabbit_port':      value => $rabbit_port;
      'oslo_messaging_rabbit/rabbit_hosts':     value => "${rabbit_host}:${rabbit_port}";
      'oslo_messaging_rabbit/rabbit_ha_queues': value => false
    }
  }

  glance_api_config {
    'DEFAULT/notification_driver':          value => $notification_driver;
    'oslo_messaging_rabbit/rabbit_virtual_host':          value => $rabbit_virtual_host;
    'oslo_messaging_rabbit/rabbit_password':              value => $rabbit_password, secret => true;
    'oslo_messaging_rabbit/rabbit_userid':                value => $rabbit_userid;
    'oslo_messaging_rabbit/rabbit_notification_exchange': value => $rabbit_notification_exchange;
    'oslo_messaging_rabbit/rabbit_notification_topic':    value => $rabbit_notification_topic;
    'oslo_messaging_rabbit/rabbit_use_ssl':               value => $rabbit_use_ssl;
    'DEFAULT/amqp_durable_queues':          value => $amqp_durable_queues_real;
  }

  if $rabbit_use_ssl {
    glance_api_config { 'oslo_messaging_rabbit/kombu_ssl_version': value => $kombu_ssl_version }

    if $kombu_ssl_ca_certs {
      glance_api_config { 'oslo_messaging_rabbit/kombu_ssl_ca_certs': value => $kombu_ssl_ca_certs }
    } else {
      glance_api_config { 'oslo_messaging_rabbit/kombu_ssl_ca_certs': ensure => absent}
    }

    if $kombu_ssl_certfile {
      glance_api_config { 'oslo_messaging_rabbit/kombu_ssl_certfile': value => $kombu_ssl_certfile }
    } else {
      glance_api_config { 'oslo_messaging_rabbit/kombu_ssl_certfile': ensure => absent}
    }

    if $kombu_ssl_keyfile {
      glance_api_config { 'oslo_messaging_rabbit/kombu_ssl_keyfile': value => $kombu_ssl_keyfile }
    } else {
      glance_api_config { 'oslo_messaging_rabbit/kombu_ssl_keyfile': ensure => absent}
    }
  } else {
    glance_api_config {
      'oslo_messaging_rabbit/kombu_ssl_version':  ensure => absent;
      'oslo_messaging_rabbit/kombu_ssl_ca_certs': ensure => absent;
      'oslo_messaging_rabbit/kombu_ssl_certfile': ensure => absent;
      'oslo_messaging_rabbit/kombu_ssl_keyfile':  ensure => absent;
    }
    if ($kombu_ssl_keyfile or $kombu_ssl_certfile or $kombu_ssl_ca_certs) {
      notice('Configuration of certificates with $rabbit_use_ssl == false is a useless config')
    }
  }
}
