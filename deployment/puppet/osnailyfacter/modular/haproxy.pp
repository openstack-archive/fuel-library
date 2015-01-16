
if (hiera('deployment_mode') == 'ha') or (hiera('deployment_mode') == 'ha_compact') {
  class { 'cluster::haproxy':
    haproxy_maxconn    => '16000',
    haproxy_bufsize    => '32768',
    primary_controller => hiera('primary_controller'),
  }
}
