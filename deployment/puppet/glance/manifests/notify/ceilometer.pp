class glance::notify::ceilometer (
) {
  glance_api_config {
    'DEFAULT/notification_driver':          value => 'messaging';
  }
}
