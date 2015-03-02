notice('MODULAR: mongo.pp')

$use_syslog       = hiera('use_syslog', true)
$debug            = hiera('debug', false)
$internal_address = hiera('internal_address')

####################################################################

class { 'openstack::mongo_secondary':
  mongodb_bind_address        => [ '127.0.0.1', $internal_address ],
  use_syslog                  => $use_syslog,
  debug                       => $debug,
  replset                     => 'ceilometer',
}

sysctl::value { 'net.ipv4.tcp_keepalive_time':
  value => '300',
}
