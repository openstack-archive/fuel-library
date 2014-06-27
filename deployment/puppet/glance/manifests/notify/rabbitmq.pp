#
# used to configure rabbitmq notifications for glance
#
#  [*rabbit_password*]
#    password to connect to the rabbit_server.
#  [*rabbit_userid*]
#    user to connect to the rabbit server. Optional. Defaults to 'guest'
#  [*rabbit_host*]
#    ip or hostname of the rabbit server. Optional. Defaults to 'localhost'
#  [*rabbit_port*]
#    port of the rabbit server. Optional. Defaults to 5672.
#  [*rabbit_virtual_host*]
#    virtual_host to use. Optional. Defaults to '/'
#  [*rabbit_use_ssl*]
#    (optional) Connect over SSL for RabbitMQ
#    Defaults to false
#  [*kombu_ssl_ca_certs*]
#    (optional) SSL certification authority file (valid only if SSL enabled).
#    Defaults to undef
#  [*kombu_ssl_certfile*]
#    (optional) SSL cert file (valid only if SSL enabled).
#    Defaults to undef
#  [*kombu_ssl_keyfile*]
#    (optional) SSL key file (valid only if SSL enabled).
#    Defaults to undef
#  [*kombu_ssl_version*]
#    (optional) SSL version to use (valid only if SSL enabled).
#    Valid values are TLSv1, SSLv23 and SSLv3. SSLv2 may be
#    available on some distributions.
#    Defaults to 'SSLv3'
#  [*rabbit_notification_exchange*]
#    Defaults  to 'glance'
#  [*rabbit_notification_topic*]
#    Defaults  to 'notifications'
#  [*rabbit_durable_queues*]
#    Defaults  to false
#
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
  $kombu_ssl_version            = 'SSLv3',
  $rabbit_notification_exchange = 'glance',
  $rabbit_notification_topic    = 'notifications',
  $rabbit_durable_queues        = false,
  $amqp_durable_queues          = false,
) {

  if $rabbit_durable_queues {
    warning('The rabbit_durable_queues parameter is deprecated, use amqp_durable_queues.')
    $amqp_durable_queues_real = $rabbit_durable_queues
  } else {
    $amqp_durable_queues_real = $amqp_durable_queues
  }

  if $rabbit_hosts {
    glance_api_config {
      'DEFAULT/rabbit_hosts':     value => join($rabbit_hosts, ',');
      'DEFAULT/rabbit_ha_queues': value => true
    }
  } else {
    glance_api_config {
      'DEFAULT/rabbit_host':      value => $rabbit_host;
      'DEFAULT/rabbit_port':      value => $rabbit_port;
      'DEFAULT/rabbit_hosts':     value => "${rabbit_host}:${rabbit_port}";
      'DEFAULT/rabbit_ha_queues': value => false
    }
  }

  glance_api_config {
    'DEFAULT/notification_driver':          value => 'messaging';
    'DEFAULT/rabbit_virtual_host':          value => $rabbit_virtual_host;
    'DEFAULT/rabbit_password':              value => $rabbit_password;
    'DEFAULT/rabbit_userid':                value => $rabbit_userid;
    'DEFAULT/rabbit_notification_exchange': value => $rabbit_notification_exchange;
    'DEFAULT/rabbit_notification_topic':    value => $rabbit_notification_topic;
    'DEFAULT/rabbit_use_ssl':               value => $rabbit_use_ssl;
    'DEFAULT/amqp_durable_queues':          value => $amqp_durable_queues_real;
  }

  if $rabbit_use_ssl {
    glance_api_config { 'DEFAULT/kombu_ssl_version': value => $kombu_ssl_version }

    if $kombu_ssl_ca_certs {
      glance_api_config { 'DEFAULT/kombu_ssl_ca_certs': value => $kombu_ssl_ca_certs }
    } else {
      glance_api_config { 'DEFAULT/kombu_ssl_ca_certs': ensure => absent}
    }

    if $kombu_ssl_certfile {
      glance_api_config { 'DEFAULT/kombu_ssl_certfile': value => $kombu_ssl_certfile }
    } else {
      glance_api_config { 'DEFAULT/kombu_ssl_certfile': ensure => absent}
    }

    if $kombu_ssl_keyfile {
      glance_api_config { 'DEFAULT/kombu_ssl_keyfile': value => $kombu_ssl_keyfile }
    } else {
      glance_api_config { 'DEFAULT/kombu_ssl_keyfile': ensure => absent}
    }
  } else {
    glance_api_config {
      'DEFAULT/kombu_ssl_version':  ensure => absent;
      'DEFAULT/kombu_ssl_ca_certs': ensure => absent;
      'DEFAULT/kombu_ssl_certfile': ensure => absent;
      'DEFAULT/kombu_ssl_keyfile':  ensure => absent;
    }
    if ($kombu_ssl_keyfile or $kombu_ssl_certfile or $kombu_ssl_ca_certs) {
      notice('Configuration of certificates with $rabbit_use_ssl == false is a useless config')
    }
  }
}
