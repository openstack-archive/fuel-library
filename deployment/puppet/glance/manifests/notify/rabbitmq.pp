#
# used to configure qpid notifications for glance
#
class glance::notify::rabbitmq(
  # TODO be able to pass in rabbitmq params
) inherits glance::api {

  class { 'glance::notify':
    notifier_strategy => 'rabbit',
  }

  glance::api::config { 'rabbitmq':
    config => {
    },
    order  => '07',
  }
}
