# == Class: osnailyfacter::wait_for_glance_backends
#
# This class is created to introduce one entry
# point to check for glance backends
#
class osnailyfacter::wait_for_glance_backends
{
  $management_vip   = hiera('management_vip')
  $service_endpoint = hiera('service_endpoint')
  $external_lb      = hiera('external_lb', false)
  $ssl_hash         = hiera_hash('use_ssl', {})

  $glance_api_protocol = get_ssl_property($ssl_hash, {}, 'glance', 'admin', 'protocol', 'http')
  $glance_api_address  = get_ssl_property($ssl_hash, {}, 'glance', 'admin', 'hostname', [$service_endpoint, $management_vip])
  $glance_api_url      = "${glance_api_protocol}://${glance_api_address}:9292"
  $glance_registry_protocol  = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'protocol', 'http')
  $glance_registry_address   = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'hostname', [$service_endpoint, $management_vip])
  $glance_registry_url       = "${glance_registry_protocol}://${glance_registry_address}:9191"

  $haproxy_stats_url = "http://${service_endpoint}:10000/;csv"

  $lb_defaults = {
    step     => 6,
    count    => 200,
    provider => 'haproxy',
    url      => $haproxy_stats_url
  }

  if $external_lb {
    $lb_glance_api = {
      provider => 'http',
      url      => $glance_api_url
    }
    $lb_glance_registry = {
      provider => 'http',
      url      => $glance_registry_url
    }
  }
  $lb_hash = {
    'glance-api' => merge(
      { name => 'glance-api' },
      $lb_glance_api
    ),
    'glance-registry' => merge(
      { name => 'glance-registry' },
      $lb_glance_registry
    )
  }

  ::osnailyfacter::wait_for_backend { 'glance':
    lb_hash     => $lb_hash,
    lb_defaults => $lb_defaults
  }

}
