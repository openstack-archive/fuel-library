class galera::mon {

  file { '/usr/local/bin/galera-mon' :
    ensure => present,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/galera/galera-mon.sh',
  }

}
