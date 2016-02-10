notice('MODULAR: twemproxy/twemproxy.pp')

$memcache_array = suffix($memcached_addresses, ':11211:1')

class { 'twemproxy':
    clients_array => $memcache_array,
}
