#
# == Class: openstack::ceilometer::radosgw
#
# Configures radosgw user to provide access for ceilometer to collect meters
#

class openstack::ceilometer::radosgw (
  $swift_rados_backend = true,
  $radosgw_user        = 'testuser',
  $radosgw_role        = 'admin',
) {

  $keys = radosgw_user($radosgw_user, $radosgw_role)

  ceilometer_config {
    'DEFAULT/swift_rados_backend'      : value => $swift_rados_backend;
    'rgw_admin_credentials/access_key' : value => $keys['access_key'];
    'rgw_admin_credentials/secret_key' : value => $keys['secret_key'];
  }
}
