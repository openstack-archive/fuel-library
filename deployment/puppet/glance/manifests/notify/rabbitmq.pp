#
# used to configure rabbitmq notifications for glance
#
class glance::notify::rabbitmq(
  $rabbit_password,
  $rabbit_userid                = 'guest',
  $rabbit_host                  = 'localhost',
  $rabbit_port                  = '5672',
  $rabbit_virtual_host          = '/',
  $rabbit_use_ssl               = false,
  $rabbit_notification_exchange = 'glance',
  $rabbit_notification_topic    = 'notifications',
  $rabbit_durable_queues        = false
) {

  Glance_api_config <| title == 'DEFAULT/notifier_strategy' |> {
    value => 'rabbit'
  }

  glance_api_config {
    'DEFAULT/rabbit_host':                  value => $rabbit_host;
    'DEFAULT/rabbit_port':                  value => $rabbit_port;
    'DEFAULT/rabbit_virtual_host':          value => $rabbit_virtual_host;
    'DEFAULT/rabbit_password':              value => $rabbit_password;
    'DEFAULT/rabbit_userid':                value => $rabbit_userid;
    'DEFAULT/rabbit_notification_exchange': value => $rabbit_notification_exchange;
    'DEFAULT/rabbit_notification_topic':    value => $rabbit_notification_topic;
    'DEFAULT/rabbit_use_ssl':               value => $rabbit_use_ssl;
    'DEFAULT/rabbit_durable_queues':        value => $rabbit_durable_queues;
  }
}
