# Used to create an rsync server to serve up the ring databases via rsync
#
# == Parameters
#
# == Dependencies
#
#   Class['swift']
#
# == Examples
#
# == Authors
#
#   Dan Bode dan@puppetlabs.com
#
# == Copyright
#
# Copyright 2011 Puppetlabs Inc, unless otherwise noted.
#
class swift::ringserver(
  $local_net_ip,
  $max_connections = 5
) {
  Class['swift::ringbuilder'] -> Class['swift::ringserver']
  rsync::server::module { "swift_server":
    path => '/etc/swift',
    lock_file => "/var/lock/swift_server.lock",
    uid => 'swift',
    gid => 'swift',
    max_connections => $max_connections,
    read_only => true,
  }
}
