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
#
# == Copyright
#
# Copyright 2011 Puppetlabs Inc, unless otherwise noted.
#
class swift::proxy::healthcheck() {

  concat::fragment { 'swift_healthcheck':
    target  => '/etc/swift/proxy-server.conf',
    content => template('swift/proxy/healthcheck.conf.erb'),
    order   => '25',
  }

}
