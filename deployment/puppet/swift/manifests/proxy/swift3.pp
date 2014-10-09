#
# Configure swift swift3.
#
# == Dependencies
#
# == Examples
#
# == Authors
#
#   Francois Charlier fcharlier@ploup.net
#   Joe Topjian joe@topjian.net
#
# == Copyright
#
# Copyright 2012 eNovance licensing@enovance.com
#
class swift::proxy::swift3(
  $ensure = 'present'
) {

  include swift::params

  package { 'swift-plugin-s3':
    ensure => $ensure,
    name   => $::swift::params::swift3,
  }

  concat::fragment { 'swift_swift3':
    target  => '/etc/swift/proxy-server.conf',
    content => template('swift/proxy/swift3.conf.erb'),
    order   => '27',
  }

}
