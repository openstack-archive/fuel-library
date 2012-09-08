#
# configures the storage backend for glance
# as a swift instance
#
#  $swift_store_auth_address - Optional. Default: '127.0.0.1:8080/v1.0/',
#
#  $swift_store_user - Optional. Default:'jdoe',
#
#  $swift_store_key - Optional. Default: 'a86850deb2742ec3cb41518e26aa2d89',
#
#  $swift_store_container - 'glance',
#
#  $swift_store_create_container_on_put - 'False'
class glance::backend::swift(
  $swift_store_user,
  $swift_store_key,
  $swift_store_auth_address = '127.0.0.1:8080/v1.0/',
  $swift_store_container = 'glance',
  $swift_store_create_container_on_put = 'False'
) inherits glance::api {

  #
  # modeled as its own config define so that any attempts to
  # define multiple backends will fail
  #
  glance::api::config { 'backend':
    config => {
      'default_store' => 'swift',
    },
    order  => '04',
  }

  glance::api::config { 'swift':
    config => {
      'swift_store_user' => $swift_store_user,
      'swift_store_key'  => $swift_store_key,
      'swift_store_auth_address' => $swift_store_auth_address,
      'swift_store_container' => $swift_store_container,
      'swift_store_create_container_on_put' => $swift_store_create_container_on_put
    },
    order  => '05',
  # this just needs to configure a section
  # in glance-api.conf
  }

}
