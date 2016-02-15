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
#
#  $swift_store_large_object_size - Optional. Default: '5120'
#
#  $swift_store_endpoint_type - Optional. Default: 'internalURL'
#
#  $default_swift_reference - Optional. Default to 'ref1'
class glance::backend::swift(
  $swift_store_user,
  $swift_store_key,
  $swift_store_auth_address = '127.0.0.1:5000/v2.0/',
  $swift_store_container = 'glance',
  $swift_store_auth_version = '2',
  $swift_store_large_object_size = '5120',
  $swift_store_create_container_on_put = false,
  $swift_store_endpoint_type = 'internalURL',
  $default_swift_reference = 'ref1',
) {

  glance_api_config {
    'glance_store/default_store':              value => 'swift';
    'glance_store/swift_store_region':         value => $swift_store_region;
    'glance_store/swift_store_container':      value => $swift_store_container;
    'glance_store/swift_store_create_container_on_put':
      value => $swift_store_create_container_on_put;
    'glance_store/swift_store_large_object_size':
      value => $swift_store_large_object_size;
    'glance_store/swift_store_endpoint_type':
      value => $swift_store_endpoint_type;

    'DEFAULT/swift_store_config_file':         value => '/etc/glance/glance-api.conf';
    'glance_store/default_swift_reference':    value => $default_swift_reference;
    "${default_swift_reference}/user":         value => $swift_store_user;
    "${default_swift_reference}/key":          value => $swift_store_key;
    "${default_swift_reference}/auth_address": value => $swift_store_auth_address;
    "${default_swift_reference}/auth_version": value => $swift_store_auth_version;
  }

}
