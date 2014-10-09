#
# Configure swift cache_errors.
#
# == Dependencies
#
# == Examples
#
#  include swift::proxy::tempurl
#
# == Authors
#
#   Mehdi Abaakouk <sileht@sileht.net>
#
# == Copyright
#
# Copyright 2012 eNovance licensing@enovance.com
#

class swift::proxy::tempurl() {

  concat::fragment { 'swift-proxy-tempurl':
    target  => '/etc/swift/proxy-server.conf',
    content => template('swift/proxy/tempurl.conf.erb'),
    order   => '29',
  }

}
