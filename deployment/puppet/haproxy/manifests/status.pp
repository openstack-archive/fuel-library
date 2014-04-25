class haproxy::status (
  $haproxy_socket = '/var/lib/haproxy/stats',
  $file = '/usr/local/bin/haproxy-status',
) {

  file { $file :
    ensure  => present,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    content => template('haproxy/haproxy-status.sh.erb'),
  }

}
