#
# This class can be sed to manage keystone middleware for swift proxy
#
# == Parameters
#  [operator_roles] a list of keystone roles a user must have to gain
#    access to Swift.
#    Optional. Dfeaults to ['admin', 'SwiftOperator']
#    Must be an array of strings
#    Swift operator roles must be defined in swift::keystone::auth because
#    keystone API access is usually not available on Swift proxy nodes.
#  [is_admin] Set to true to allow users to set ACLs on their account.
#    Optional. Defaults to true.
#  [cache] the cache backend to use
#    Optional. Defaults to 'swift.cache'
#
# == Authors
#
#  Dan Bode dan@puppetlabs.com
#  François Charlier fcharlier@ploup.net
#

class swift::proxy::keystone(
  $operator_roles      = ['admin', 'SwiftOperator'],
  $is_admin            = true,
  $cache               = 'swift.cache'
) {

  require 'keystone::python'

  concat::fragment { 'swift_keystone':
    target  => '/etc/swift/proxy-server.conf',
    content => template('swift/proxy/keystone.conf.erb'),
    order   => '79',
  }

}
