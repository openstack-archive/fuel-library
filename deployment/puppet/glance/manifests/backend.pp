#
# used to model the line in the file
# that configures which storage backend
# to use
#
class glance::backend(
  $default_store
) {
  glance::api::config { 'backend':
    config => {
      'default_store' => $default_store
    },
    order  => '02',
  }
}
