#
# Configures the swift proxy memcache server
#
# [*memcache_servers*] A list of the memcache servers to be used. Entries
#  should be in the form host:port.
#
# == Dependencies
#
#   Class['memcached']
#
# == Examples
#
# == Authors
#
#   Dan Bode dan@puppetlabs.com
#
# == Copyright
#
# Copyright 2011 Puppetlabs Inc, unless otherwise noted.
#
class swift::proxy::cache(
  $memcache_servers = ['127.0.0.1:11211']
) {

  # require the memcached class if its on the same machine
  if $memcache_servers =~ /^127\.0\.0\.1/ {
    Class['memcached'] -> Class['swift::proxy::cache']
  }

  concat::fragment { 'swift_cache':
    target  => '/etc/swift/proxy-server.conf',
    content => template('swift/proxy/cache.conf.erb'),
    order   => '23',
  }

}
