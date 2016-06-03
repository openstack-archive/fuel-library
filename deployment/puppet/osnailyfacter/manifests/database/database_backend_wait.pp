# == Class: osnailyfacter::database::database_backend_wait
#
# This is the code to use to ensure the mysql backends are up before preceding.
# It can be used as a standalone task or included anywhere where you need to
# wait for the mysql backend to be up.
#
# === Parameters
#
# None
#
class osnailyfacter::database::database_backend_wait {
  $management_vip     = hiera('management_vip')
  $database_vip       = hiera('database_vip', $management_vip)
  $haproxy_stats_port = '10000'
  $haproxy_stats_url  = "http://${database_vip}:${haproxy_stats_port}/;csv"
  $external_lb        = hiera('external_lb', false)
  $lb_defaults        = { 'provider' => 'haproxy', 'url' => $haproxy_stats_url }

  if $external_lb {
    $lb_backend_provider = 'http'
    $lb_url = "http://${database_vip}:49000"
  }

  $lb_hash = {
    mysql      => {
      name     => 'mysqld',
      provider => $lb_backend_provider,
      url      => $lb_url
    }
  }

  ::osnailyfacter::wait_for_backend {'mysql':
    lb_hash     => $lb_hash,
    lb_defaults => $lb_defaults
  }
}
