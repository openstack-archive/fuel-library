#
# used to model the line in the file
# that configures which storage backend
# to use
#
class glance::notify(
  $notifier_strategy
) {

  glance::api::config { 'notify':
    config => {
      'notifier_strategy' => $notifier_strategy,
    },
    order  => '06',
  }
}
