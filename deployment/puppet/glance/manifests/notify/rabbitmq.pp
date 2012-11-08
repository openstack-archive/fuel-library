#
# used to configure qpid notifications for glance
#
class glance::notify::rabbitmq(
  $rabbit_password,
  $rabbit_userid   = 'guest',
  $rabbit_host     = 'localhost'
) inherits glance::api {

  glance_api_config {
    'DEFAULT/notifier_strategy': value => 'rabbit';
    'DEFAULT/rabbit_host':       value => $rabbit_host;
    'DEFAULT/rabbit_password':   value => $rabbit_password;
    'DEFAULT/rabbit_userid':     value => $rabbit_userid;
  }
}
