#schedulee this class should probably never be declared except
# from the virtualization implementation of the compute node
class nova::compute(
  $enabled = false,
  $vnc_enabled = true,
  $vncserver_proxyclient_address = '127.0.0.1',
  $novncproxy_base_url = 'http://127.0.0.1:6080/vnc_auto.html'
) {

  nova::generic_service { 'compute':
    enabled      => $enabled,
    package_name => $::nova::params::compute_package_name,
    service_name => $::nova::params::compute_service_name,
    before       => Exec['networking-refresh']
  }

  # config for vnc proxy
  nova_config {
    'vnc_enabled': value => $vnc_enabled;
    'vncserver_proxyclient_address': value => $vncserver_proxyclient_address;
  }

}
