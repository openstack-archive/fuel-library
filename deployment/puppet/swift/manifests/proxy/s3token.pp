# == Class: swift::proxy::s3token
#
# Configure swift s3token.
#
# === Parameters
#
# [*auth_host*]
#   (optional) The keystone host
#   Defaults to 127.0.0.1
#
# [*auth_port*]
#   (optional) The Keystone client API port
#   Defaults to 5000
#
# [*auth_protocol*]
#   (optional) http or https
#    Defaults to http
#
# == Dependencies
#
# == Examples
#
# == Authors
#
#   Francois Charlier fcharlier@ploup.net
#
# == Copyright
#
# Copyright 2012 eNovance licensing@enovance.com
#
class swift::proxy::s3token(
  $auth_host = '127.0.0.1',
  $auth_port = '35357',
  $auth_protocol = 'http'
) {

  include ::keystone::python

  concat::fragment { 'swift_s3token':
    target  => '/etc/swift/proxy-server.conf',
    content => template('swift/proxy/s3token.conf.erb'),
    order   => '28',
  }
}
