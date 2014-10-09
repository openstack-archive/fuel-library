#
# Configure swift cache_errors.
#
# == Dependencies
#
# == Examples
#
#  include 'swift::proxy::staticweb'
#
# == Authors
#
#   Mehdi Abaakouk <sileht@sileht.net>
#
# == Copyright
#
# Copyright 2012 eNovance licensing@enovance.com
#

class swift::proxy::staticweb() {

  concat::fragment { 'swift-proxy-staticweb':
    target  => '/etc/swift/proxy-server.conf',
    content => template('swift/proxy/staticweb.conf.erb'),
    order   => '32',
  }

}
