#
# Configure swift healthcheck.
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
define swift::storage::filter::healthcheck(
) {

  concat::fragment { "swift_healthcheck_${name}":
    target  => "/etc/swift/${name}-server.conf",
    content => template('swift/proxy/healthcheck.conf.erb'),
    order   => '25',
  }

}
