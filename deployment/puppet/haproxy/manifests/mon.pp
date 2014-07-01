class haproxy::mon (
  $haproxy_socket = '/var/lib/haproxy/stats',
  $file = '/usr/local/bin/haproxy-mon',
) {

  file { $file :
    ensure  => present,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    content => template('haproxy/haproxy-mon.py.erb'),
  }

}
