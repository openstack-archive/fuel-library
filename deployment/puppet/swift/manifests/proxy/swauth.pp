# == Class: swift::proxy::swauth
#
# === Parameters:
#
# [*package_ensure*]
#   The status of the python-swauth package.
#   Defaults to 'present'
#
# [*swauth_endpoint*]
#   (optional) The endpoint used to autenticate to Swauth WSGI.
#   Defaults to '127.0.0.1'
#
# [*swauth_super_admin_key*]
#   (optional) The Swauth WSGI filter admin key.
#   Defaults to 'swauthkey'
#
#
class swift::proxy::swauth(
  $swauth_endpoint = '127.0.0.1',
  $swauth_super_admin_key = 'swauthkey',
  $package_ensure = 'present'
) {

  package { 'python-swauth':
    ensure => $package_ensure,
    before => Package['swift-proxy'],
  }

  concat::fragment { 'swift_proxy_swauth':
    target  => '/etc/swift/proxy-server.conf',
    content => template('swift/proxy/swauth.conf.erb'),
    order   => '20',
  }

}
