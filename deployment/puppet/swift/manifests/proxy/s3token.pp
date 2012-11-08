#
# Configure swift s3token.
#
# == Parameters
#  [auth_host] the keystone host
#   Optional. Defaults to 127.0.0.1
#  [auth_port] the Keystone client API port
#   Optional. Defaults to 5000
#  [auth_protocol] http or https
#   Optional. Defaults to http
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
class swift::proxy::s3token(
  $auth_host = '127.0.0.1',
  $auth_port = 5000,
  $auth_protocol = 'http'
) {

  concat::fragment { 'swift_s3token':
    target  => '/etc/swift/proxy-server.conf',
    content => template('swift/proxy/s3token.conf.erb'),
    order   => '28',
  }

  include 'keystone::python'
}
