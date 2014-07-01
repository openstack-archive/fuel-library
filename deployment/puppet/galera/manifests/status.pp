class galera::status {

  file { '/usr/local/bin/galera-status' :
    ensure => present,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/galera/galera-status.sh',
  }

}
