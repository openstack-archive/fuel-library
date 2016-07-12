# == Class: osnailyfacter::wait_for_nova_backends
#
# This class is created to introduce one entry point to check for nova backends
# By default it will check for *all* nova service backends but can be
# configured to only wait for a particular service.
#
# === Parameters
#
# [*backends*]
#  (Optional) List of backend services to wait for
#  Defaults to ['nova-api', 'nova-metadata-api', 'nova-novncproxy']
#
# [*management_vip*]
#  (Optional) Management vip address
#  Defaults to hiera('management_vip')
#
# [*service_endpoint*]
#  (Optional) Service endpoint ip address
#  Defaults to hiera('service_endpoint')
#
# [*exeternal_lb*]
#  (Optional) Flag to indicate if external loadbalancers are used.
#  Defaults to hiera('exernal_lb', false)
#
# [*ssl_hash*]
#  (Optional) Hash of external ssl information
#  Defaults to hiera_hash('use_ssl', {})
#
class osnailyfacter::wait_for_nova_backends (
  $backends         = ['nova-api', 'nova-metadata-api', 'nova-novncproxy'],
  $management_vip   = hiera('management_vip'),
  $service_endpoint = hiera('service_endpoint'),
  $external_lb      = hiera('external_lb', false),
  $ssl_hash         = hiera_hash('use_ssl', {}),
) {

  $nova_api_protocol = get_ssl_property($ssl_hash, {}, 'nova', 'internal', 'protocol', 'http')
  $nova_api_address  = get_ssl_property($ssl_hash, {}, 'nova', 'internal', 'hostname', [$service_endpoint, $management_vip])

  $nova_api_url          = "${nova_api_protocol}://${nova_api_address}:8774"
  $nova_metadata_api_url = "${nova_api_protocol}://${nova_api_address}:8775"
  $nova_novncproxy_url   = "${nova_api_protocol}://${nova_api_address}:6080"

  $haproxy_stats_url = "http://${service_endpoint}:10000/;csv"

  $lb_defaults = {
    step     => 6,
    count    => 200,
    provider => 'haproxy',
    url      => $haproxy_stats_url
  }

  if $external_lb {
    $lb_nova_api = {
      provider => 'http',
      url      => $nova_api_url
    }
    $lb_nova_metadata_api = {
      provider => 'http',
      url      => $nova_metadata_api_url,
    }
    $lb_nova_novncproxy = {
      provider => 'http',
      url      => $nova_novncproxy_url,
    }
  }
  $all_backend_hash = {
    'nova-api'          => merge(
      { name => 'nova-api' },
      $lb_nova_api
    ),
    'nova-metadata-api' => merge(
      { name => 'nova-metadata-api' },
      $lb_nova_metadata_api
    ),
    'nova-novncproxy'   => merge (
      { name => 'nova-novncproxy' },
      $lb_nova_novncproxy
    )
  }

  # use difference from the keys of $all_backend_hash to get the keys we don't
  # want to monitor
  $keys_to_remove = difference(keys($all_backend_hash), $backends)
  $lb_hash = delete($all_backend_hash, $keys_to_remove)

  if empty($lb_hash) {
    fail('No nova backends to monitor')
  }

  ::osnailyfacter::wait_for_backend { 'nova-api':
    lb_hash     => $lb_hash,
    lb_defaults => $lb_defaults
  }
}
