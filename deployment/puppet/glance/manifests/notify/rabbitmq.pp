#
# used to configure rabbitmq notifications for glance
#
class glance::notify::rabbitmq(
  $rabbit_password,
  $rabbit_userid                = 'guest',
  $rabbit_host                  = 'localhost',
  $rabbit_port                  = '5672',
  $rabbit_hosts                 = false,
  $rabbit_virtual_host          = '/',
  $rabbit_use_ssl               = false,
  $rabbit_notification_exchange = 'glance',
  $rabbit_notification_topic    = 'notifications',
  $rabbit_durable_queues        = false,
  $amqp_durable_queues          = false,
) {

  if $rabbit_durable_queues {
    warning('The rabbit_durable_queues parameter is deprecated, use amqp_durable_queues.')
    glance_api_config {
      'DEFAULT/amqp_durable_queues':          value => $rabbit_durable_queues;
    }
  } else {
    glance_api_config {
      'DEFAULT/amqp_durable_queues':          value => $amqp_durable_queues;
    }
  }

  if $rabbit_hosts {
    glance_api_config {
      'DEFAULT/rabbit_hosts':          value => join($rabbit_hosts, ',');
      'DEFAULT/rabbit_ha_queues':      value => true;
      'DEFAULT/kombu_reconnect_delay': value => 5.0;
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
  }
}
