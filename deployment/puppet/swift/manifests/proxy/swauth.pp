# [*swauth_endpoint*]
# [*swauth_super_admin_user*]
class swift::proxy::swauth(
  $swauth_endpoint = '127.0.0.1',
  $swauth_super_admin_key = 'swauthkey',
  $package_ensure = 'present'
) {

  package { 'python-swauth':
    ensure  => $package_ensure,
    before  => Package['swift-proxy'],
  }

  concat::fragment { 'swift_proxy_swauth':
    target  => '/etc/swift/proxy-server.conf',
    content => template('swift/proxy/swauth.conf.erb'),
    order   => '20',
  }

}
