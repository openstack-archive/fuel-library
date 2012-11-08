#
# used to configure qpid notifications for glance
#
class glance::notify::qpid(
) inherits glance::api {

  class { 'glance::notify':
    notifier_strategy => 'qpid',
  }

  glance::api::config { 'qpid':
    config => {
    },
    order  => '07',
  }
}
