# == Class: nova::compute::serial
#
# Configures nova serial console
#
# === Parameters:
#
# [*port_range*]
#   (optional) Range of TCP ports to use for serial ports on compute hosts
#   Defaults to 10000:20000
#
# [*base_url*]
#   (optional) URL that gets passed to the clients
#   Defaults to 'ws://127.0.0.1:6083/'
#
# [*listen*]
#   IP address on which instance serial console should listen
#   Defaults to 127.0.0.1
#
# [*proxyclient_address*]
#   The address to which proxy clients (like nova-serialproxy)
#   should connect (string value)
#   Defaults to 127.0.0.1
#
class nova::compute::serial(
  $port_range            = '10000:20000',
  $base_url              = 'ws://127.0.0.1:6083/',
  $listen                = '127.0.0.1',
  $proxyclient_address   = '127.0.0.1',
) {


  nova_config {
    'serial_console/enabled':             value => true;
    'serial_console/port_range':          value => $port_range;
    'serial_console/base_url':            value => $base_url;
    'serial_console/listen':              value => $listen;
    'serial_console/proxyclient_address': value => $proxyclient_address;
  }
}
