#schedulee this class should probably never be declared except
# from the virtualization implementation of the compute node
class nova::compute(
  $enabled                       = false,
  $ensure_package                = 'present',
  $vnc_enabled                   = true,
  $vncserver_proxyclient_address = '127.0.0.1',
  $vncproxy_host                 = false,
  $vncproxy_protocol             = 'http',
  $vncproxy_port                 = '6080',
  $vncproxy_path                 = '/vnc_auto.html',
  $virtio_nic                    = false
 ) {

  include nova::params

  if ($vnc_enabled) {
    if !($vncproxy_host) {
      warning("VNC is enabled and \$vncproxy_host must be specified nova::compute assumes that it can collect the exported resource: Nova_config[novncproxy_base_url]")
      Nova_config <<| title == 'novncproxy_base_url' |>>
    } else {
      $vncproxy_base_url = "${vncproxy_protocol}://${vncproxy_host}:${vncproxy_port}${vncproxy_path}"
      # config for vnc proxy
      nova_config {
        'novncproxy_base_url': value => $vncproxy_base_url;
      }
    }
  }

  nova_config {
    'vnc_enabled': value => $vnc_enabled;
    'vncserver_proxyclient_address': value => $vncserver_proxyclient_address;
  }

  package { 'bridge-utils':
    ensure => present,
    before => Nova::Generic_service['compute'],
  }

  nova::generic_service { 'compute':
    enabled        => $enabled,
    package_name   => $::nova::params::compute_package_name,
    service_name   => $::nova::params::compute_service_name,
    ensure_package => $ensure_package,
    before         => Exec['networking-refresh']
  }

  if $virtio_nic {
    # Enable the virtio network card for instances
    nova_config { 'libvirt_use_virtio_for_bridges': value => 'True' }
  }

}
