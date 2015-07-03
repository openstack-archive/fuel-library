# == class: glance::backend::swift
#
# configures the storage backend for glance
# as a swift instance
#
# === parameters:
#
#  [*swift_store_user*]
#    Required. Swift store user.
#
#  [*swift_store_key*]
#    Required. Swift store key.
#
#  [*swift_store_auth_address*]
#    Optional. Default: '127.0.0.1:5000/v2.0/'
#
#  [*swift_store_container*]
#    Optional. Default: 'glance'
#
#  [*swift_store_auth_version*]
#    Optional. Default: '2'
#
#  [*swift_store_large_object_size*]
#    Optional. Default: '5120'
#
#  [*swift_store_create_container_on_put*]
#    Optional. Default: 'False'
#
#  [*swift_store_endpoint_type*]
#    Optional. Default: 'internalURL'
#
class glance::backend::swift(
  $swift_store_user,
  $swift_store_key,
  $swift_store_auth_address = '127.0.0.1:5000/v2.0/',
  $swift_store_container = 'glance',
  $swift_store_auth_version = '2',
  $swift_store_large_object_size = '5120',
  $swift_store_create_container_on_put = false,
  $swift_store_endpoint_type = 'internalURL'
) {

  glance_api_config {
    'glance_store/default_store':            value => 'swift';
    'glance_store/swift_store_user':         value => $swift_store_user;
    'glance_store/swift_store_key':          value => $swift_store_key;
    'glance_store/swift_store_auth_address': value => $swift_store_auth_address;
    'glance_store/swift_store_container':    value => $swift_store_container;
    'glance_store/swift_store_auth_version': value => $swift_store_auth_version;
    'glance_store/swift_store_create_container_on_put':
      value => $swift_store_create_container_on_put;
    'glance_store/swift_store_large_object_size':
      value => $swift_store_large_object_size;
    'glance_store/swift_store_endpoint_type':
      value => $swift_store_endpoint_type;
  }

  glance_cache_config {
    'glance_store/swift_store_user':         value => $swift_store_user;
    'glance_store/swift_store_key':          value => $swift_store_key;
    'glance_store/swift_store_auth_address': value => $swift_store_auth_address;
    'glance_store/swift_store_container':    value => $swift_store_container;
    'glance_store/swift_store_auth_version': value => $swift_store_auth_version;
    'glance_store/swift_store_create_container_on_put':
      value => $swift_store_create_container_on_put;
    'glance_store/swift_store_large_object_size':
      value => $swift_store_large_object_size;
  }

}
