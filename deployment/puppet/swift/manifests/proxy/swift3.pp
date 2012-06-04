#
# Configure swift swift3.
#
# == Dependencies
#
# == Examples
#
# == Authors
#
#   François Charlier fcharlier@ploup.net
#
# == Copyright
#
# Copyright 2012 eNovance licensing@enovance.com
#
class swift::proxy::swift3() {

  concat::fragment { 'swift_swift3':
    target  => '/etc/swift/proxy-server.conf',
    content => template('swift/proxy/swift3.conf.erb'),
    order   => '27',
  }

}
