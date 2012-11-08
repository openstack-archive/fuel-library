#
# Configure swift recon.
#
# == Parameters
#  [cache_path] The path for recon cache
#    Optional. Defaults to '/var/cache/swift/'
#
# == Dependencies
#
# == Examples
#
# == Authors
#
#   Dan Bode dan@puppetlabs.com
#   François Charlier fcharlier@ploup.net
#
# == Copyright
#
# Copyright 2011 Puppetlabs Inc, unless otherwise noted.
#
define swift::storage::filter::recon(
  $cache_path = '/var/cache/swift'
) {

  concat::fragment { "swift_recon_${name}":
    target  => "/etc/swift/${name}-server.conf",
    content => template('swift/recon.conf.erb'),
    order   => '35',
  }

}
