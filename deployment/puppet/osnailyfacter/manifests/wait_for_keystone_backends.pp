# == Class: osnailyfacter::wait_for_keystone_backends
#
# This class is created to introduce one entry
# point to check for keystone backends
#
class osnailyfacter::wait_for_keystone_backends
{
  $management_vip   = hiera('management_vip')
  $service_endpoint = hiera('service_endpoint')
  $external_lb      = hiera('external_lb', false)
  $ssl_hash         = hiera_hash('use_ssl', {})

  $admin_identity_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
  $admin_identity_address  = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [$service_endpoint, $management_vip])
  $admin_identity_url      = "${admin_identity_protocol}://${admin_identity_address}:35357/v3"
  $internal_auth_protocol  = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
  $internal_auth_address   = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$service_endpoint, $management_vip])
  $internal_auth_url       = "${internal_auth_protocol}://${internal_auth_address}:5000/v3"

  $haproxy_stats_url = "http://${service_endpoint}:10000/;csv"

  $lb_defaults = {
    step     => 6,
    count    => 200,
    provider => 'haproxy',
    url      => $haproxy_stats_url
  }

  if $external_lb {
    $lb_keystone_admin =
    {
      provider => 'http',
      url      => $admin_identity_url
    }
    $lb_keystone_public = {
      provider => 'http',
      url      => $internal_auth_url
    }
  }
  $lb_hash = {
    'keystone-admin' => merge(
      { name => 'keystone-2' },
      $lb_keystone_admin
    ),
    'keystone-public' => merge(
      { name => 'keystone-1' },
      $lb_keystone_public
    )
  }

  ::osnailyfacter::wait_for_backend {'keystone':
    lb_hash     => $lb_hash,
    lb_defaults => $lb_defaults
  }

}
