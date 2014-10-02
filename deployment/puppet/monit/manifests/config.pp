class monit::config {

  file {'/etc/monit/monitrc':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => 0600,
    content => template('monit/monitrc.erb'),
  }

}
