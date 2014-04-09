# == Class: nova::compute::spice
#
# Configure spice on the compute side
#
# === Parameters:
#
# [*agent_enabled*]
#   (optional) enable spice guest agent support
#   Defaults to true
#
# [*server_listen*]
#   (optional)  IP address on which instance spice servers should listen
#   Defaults to undef
#
# [*server_proxyclient_address*]
#   (optional) Management IP Address on which instance spiceservers will
#   listen on the compute host.
#   Defaults to '127.0.0.1'
#
# [*keymap*]
#   (optional) keymap for spice
#   Defaults to 'en-us'
#
# [*proxy_host*]
#   (optional) Host for the html5 console proxy
#   Defaults to false
#
# [*proxy_port*]
#   (optional) Port for the html5 console proxy
#   Defaults to '6082'
#
# [*proxy_protocol*]
#   (optional) Protocol for the html5 console proxy
#   Defaults to 'http'
#
# [*proxy_path*]
#   (optional) Path of the spice html file for the html5 console proxy
#   Defaults to '/spice_auto.html'
#
class nova::compute::spice(
  $agent_enabled                    = true,
  $server_listen                    = undef,
  $server_proxyclient_address       = '127.0.0.1',
  $keymap                           = 'en-us',
  $proxy_host                       = false,
  $proxy_protocol                   = 'http',
  $proxy_port                       = '6082',
  $proxy_path                       = '/spice_auto.html'
) {

  if $proxy_host {
    $html5proxy_base_url = "${proxy_protocol}://${proxy_host}:${proxy_port}${proxy_path}"
    nova_config {
      'spice/html5proxy_base_url': value => $html5proxy_base_url;
    }
  }

  nova_config {
    'spice/enabled':                    value => true;
    'spice/agent_enabled':              value => $agent_enabled;
    'spice/server_listen':              value => $server_listen;
    'spice/server_proxyclient_address': value => $server_proxyclient_address;
    'spice/keymap':                     value => $keymap;
  }
}
