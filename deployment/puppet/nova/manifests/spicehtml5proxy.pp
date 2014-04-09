#  == Class: nova::spice
#
# Configure spicehtml5 proxy
#
# SPICE is a new protocol which aims to address all the limitations in VNC,
# to provide good remote desktop support. This class aim to configure the nova
# services in charge of proxing websocket spicehtml5 request to kvm spice
#
# === Parameters:
#
# [*enabled*]
#   (optional) enable spicehtml5proxy service
#   true/false
#
# [*manage_service*]
#   (optional) Whether to start/stop the service
#   Defaults to true
#
# [*host*]
#   (optional) Listen address for the html5 console proxy
#   Defaults to 0.0.0.0
#
# [*port*]
#   (optional) Listen port for the html5 console proxy
#   Defaults to 6082
#
# [*ensure_package*]
#   (optional) Ensure package state
#   Defaults to 'present'
#
class nova::spicehtml5proxy(
  $enabled        = false,
  $manage_service = true,
  $host           = '0.0.0.0',
  $port           = '6082',
  $ensure_package = 'present'
) {

  include nova::params

  nova_config {
    'DEFAULT/spicehtml5proxy_host': value => $host;
    'DEFAULT/spicehtml5proxy_port': value => $port;
  }

  nova::generic_service { 'spicehtml5proxy':
    enabled        => $enabled,
    manage_service => $manage_service,
    package_name   => $::nova::params::spicehtml5proxy_package_name,
    service_name   => $::nova::params::spicehtml5proxy_service_name,
    ensure_package => $ensure_package,
  }
}

