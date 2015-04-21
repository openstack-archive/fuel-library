#
# used to configure qpid notifications for sahara
#
class sahara::notify::qpid(
) {

  sahara_config {
    'DEFAULT/notifier_driver': value => 'messaging';
  }
}
