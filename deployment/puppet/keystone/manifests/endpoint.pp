# == Class: keystone::endpoint
#
# Creates the auth endpoints for keystone
#
# === Parameters
#
# [*public_url*]
#   (optional) Public url for keystone endpoint. (Defaults to 'http://127.0.0.1:5000')
#   This url should *not* contain any version or trailing '/'.
#
# [*internal_url*]
#   (optional) Internal url for keystone endpoint. (Defaults to $public_url)
#   This url should *not* contain any version or trailing '/'.
#
# [*admin_url*]
#   (optional) Admin url for keystone endpoint. (Defaults to 'http://127.0.0.1:35357')
#   This url should *not* contain any version or trailing '/'.
#
# [*region*]
#   (optional) Region for endpoint. (Defaults to 'RegionOne')
#
# [*version*]
#   (optional) API version for endpoint. Appended to all endpoint urls. (Defaults to 'v2.0')
#
# [*user_domain*]
#   (Optional) Domain for $auth_name
#   Defaults to undef (use the keystone server default domain)
#
# [*project_domain*]
#   (Optional) Domain for $tenant (project)
#   Defaults to undef (use the keystone server default domain)
#
# [*default_domain*]
#   (Optional) Domain for $auth_name and $tenant (project)
#   If keystone_user_domain is not specified, use $keystone_default_domain
#   If keystone_project_domain is not specified, use $keystone_default_domain
#   Defaults to undef
#
# === Examples
#
#  class { 'keystone::endpoint':
#    public_url   => 'https://154.10.10.23:5000',
#    internal_url => 'https://11.0.1.7:5000',
#    admin_url    => 'https://10.0.1.7:35357',
#  }
#
class keystone::endpoint (
  $public_url        = 'http://127.0.0.1:5000',
  $internal_url      = undef,
  $admin_url         = 'http://127.0.0.1:35357',
  $version           = 'v2.0',
  $region            = 'RegionOne',
  $user_domain       = undef,
  $project_domain    = undef,
  $default_domain    = undef,
) {

  $public_url_real = "${public_url}/${version}"
  $admin_url_real = "${admin_url}/${version}"

  if $internal_url {
    $internal_url_real = "${internal_url}/${version}"
  } else {
    $internal_url_real = "${public_url}/${version}"
  }

  keystone::resource::service_identity { 'keystone':
    configure_user      => false,
    configure_user_role => false,
    service_type        => 'identity',
    service_description => 'OpenStack Identity Service',
    public_url          => $public_url_real,
    admin_url           => $admin_url_real,
    internal_url        => $internal_url_real,
    region              => $region,
    user_domain         => $user_domain,
    project_domain      => $project_domain,
    default_domain      => $default_domain,
  }

}
