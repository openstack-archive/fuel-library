#
# used to configure rabbitmq notifications for sahara
#
class sahara::notify::rabbitmq(
  $enable_notifications  = true,
) {

  sahara_config {
    'DEFAULT/enable_notifications': value => $enable_notifications;
    'DEFAULT/notification_driver':  value => 'messaging';
  }

}
