#
# This class can be sed to manage keystone middleware for swift proxy
#
# == Parameters
#
#  [*operator_roles*]
#    (Optional) a list of keystone roles a user must have to gain access to Swift.
#    Defaults to ['admin', 'SwiftOperator']
#    Must be an array of strings
#    Swift operator roles must be defined in swift::keystone::auth because
#    keystone API access is usually not available on Swift proxy nodes.
#
#  [*is_admin*]
#   (Optional) Set to true to allow users to set ACLs on their account.
#    Defaults to true.
#
# [*reseller_prefix*]
#   (Optional) The prefix used for reseller URL.
#   Defaults to 'AUTH_'
#
# == Authors
#
#  Dan Bode dan@puppetlabs.com
#  Francois Charlier fcharlier@ploup.net
#
class swift::proxy::keystone(
  $operator_roles      = ['admin', 'SwiftOperator'],
  $is_admin            = true,
  $reseller_prefix     = 'AUTH_'
) {

  concat::fragment { 'swift_keystone':
    target  => '/etc/swift/proxy-server.conf',
    content => template('swift/proxy/keystone.conf.erb'),
    order   => '79',
  }

}
