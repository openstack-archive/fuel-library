notice('MODULAR: twemproxy/twemproxy.pp')

$memcached_addresses = hiera('memcached_addresses')
$memcache_array = suffix($memcached_addresses, ':11211:1')

class { 'twemproxy':
    clients_array => $memcache_array,
}
