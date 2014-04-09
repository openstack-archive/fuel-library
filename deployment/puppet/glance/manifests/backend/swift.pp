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
  $swift_store_auth_address = '127.0.0.1:5000/v2.0/',
  $swift_store_container = 'glance',
  $swift_store_auth_version = '2',
  $swift_store_create_container_on_put = false
) {

  glance_api_config {
    'DEFAULT/default_store':            value => 'swift';
    'DEFAULT/swift_store_user':         value => $swift_store_user;
    'DEFAULT/swift_store_key':          value => $swift_store_key;
    'DEFAULT/swift_store_auth_address': value => $swift_store_auth_address;
    'DEFAULT/swift_store_container':    value => $swift_store_container;
    'DEFAULT/swift_store_auth_version': value => $swift_store_auth_version;
    'DEFAULT/swift_store_create_container_on_put':
      value => $swift_store_create_container_on_put;
  }

  glance_cache_config {
    'DEFAULT/swift_store_user':         value => $swift_store_user;
    'DEFAULT/swift_store_key':          value => $swift_store_key;
    'DEFAULT/swift_store_auth_address': value => $swift_store_auth_address;
    'DEFAULT/swift_store_container':    value => $swift_store_container;
    'DEFAULT/swift_store_auth_version': value => $swift_store_auth_version;
    'DEFAULT/swift_store_create_container_on_put':
      value => $swift_store_create_container_on_put;
  }

}
