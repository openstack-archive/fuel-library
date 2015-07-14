# The ceilometer::agent::auth class helps configure common
# auth settings for the agents.
#
# == Parameters
#  [*auth_url*]
#    the keystone public endpoint
#    Optional. Defaults to 'http://localhost:5000/v2.0'
#
#  [*auth_region*]
#    the keystone region of this node
#    Optional. Defaults to 'RegionOne'
#
#  [*auth_user*]
#    the keystone user for ceilometer services
#    Optional. Defaults to 'ceilometer'
#
#  [*auth_password*]
#    the keystone password for ceilometer services
#    Required.
#
#  [*auth_tenant_name*]
#    the keystone tenant name for ceilometer services
#    Optional. Defaults to 'services'
#
#  [*auth_tenant_id*]
#    the keystone tenant id for ceilometer services.
#    Optional. Defaults to empty.
#
#  [*auth_cacert*]
#    Certificate chain for SSL validation. Optional; Defaults to 'None'
#
class ceilometer::agent::auth (
  $auth_password,
  $auth_url         = 'http://localhost:5000/v2.0',
  $auth_region      = 'RegionOne',
  $auth_user        = 'ceilometer',
  $auth_tenant_name = 'services',
  $auth_tenant_id   = '',
  $auth_cacert      = undef,
) {

  if ! $auth_cacert {
    ceilometer_config { 'service_credentials/os_cacert': ensure => absent }
  } else {
    ceilometer_config { 'service_credentials/os_cacert': value => $auth_cacert }
  }

  ceilometer_config {
    'service_credentials/os_auth_url'    : value => $auth_url;
    'service_credentials/os_region_name' : value => $auth_region;
    'service_credentials/os_username'    : value => $auth_user;
    'service_credentials/os_password'    : value => $auth_password, secret => true;
    'service_credentials/os_tenant_name' : value => $auth_tenant_name;
  }

  if ($auth_tenant_id != '') {
    ceilometer_config {
      'service_credentials/os_tenant_id' : value => $auth_tenant_id;
    }
  }

}
