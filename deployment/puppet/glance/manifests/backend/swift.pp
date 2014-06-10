#
# configures the storage backend for glance
# as a swift instance
#
#  $swift_store_user - Required.
#
#  $swift_store_key - Required.
#
#  $swift_store_auth_address - Optional. Default: '127.0.0.1:5000/v2.0/'
#
#  $swift_store_container - Optional. Default: 'glance'
#
#  $swift_store_auth_version - Optional. Default: '2'
#
#  $swift_store_create_container_on_put - Optional. Default: 'False'
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
