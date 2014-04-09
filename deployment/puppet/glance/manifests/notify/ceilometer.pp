class glance::notify::ceilometer (
) {
  glance_api_config {
    'DEFAULT/rabbit_notification_exchange': value => 'glance';
    'DEFAULT/rabbit_notification_topic':    value => 'notifications';
    'DEFAULT/rabbit_durable_queues':        value => 'False';
    'DEFAULT/notification_driver':          value => 'messaging';
  }
}
