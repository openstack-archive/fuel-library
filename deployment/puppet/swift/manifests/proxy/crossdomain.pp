#
# Configure swift crossdomain.
#
# == Examples
#
#  include swift::proxy::crossdomain
#
# == Parameters
#
# [*cross_domain_policy*]
#   cross_domain_policy value according to http://docs.openstack.org/developer/swift/crossdomain.html
#   default: <allow-access-from domain="*" secure="false" />
#
class swift::proxy::crossdomain (
  $cross_domain_policy = '<allow-access-from domain="*" secure="false" />',
) {

  concat::fragment { 'swift_crossdomain':
    target  => '/etc/swift/proxy-server.conf',
    content => template('swift/proxy/crossdomain.conf.erb'),
    order   => '35',
  }

}
