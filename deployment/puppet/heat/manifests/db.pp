class heat::db (
  $sql_connection = 'mysql://heat:heat@localhost/heat'
) {

  include heat::params

  $db_sync_command = $::heat::params::db_sync_command
  $legacy_db_sync_command = $::heat::params::legacy_db_sync_command

  Package<| title == 'heat-common' |> -> Class['heat::db']
  Class['heat::db::mysql']            -> Class['heat::db']

  validate_re($sql_connection,
    '(mysql):\/\/(\S+:\S+@\S+\/\S+)?')

  case $sql_connection {
    /^mysql:\/\//: {
      $backend_package = false
      include mysql::python
    }
    default: {
      fail('Unsupported backend configured')
    }
  }

  if $backend_package and !defined(Package[$backend_package]) {
    package {'heat-backend-package':
      ensure => present,
      name   => $backend_package,
    }
  }

  heat_config {
    'DEFAULT/sql_connection': value => $sql_connection;
  }

  file { 'db_sync_script' :
    ensure  => present,
    path    => $::heat::params::heat_db_sync_command,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('heat/heat_db_sync.sh.erb'),
  }

  exec { 'heat_db_sync' :
    command     => $::heat::params::heat_db_sync_command,
    path        => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin', '/usr/local/bin', '/usr/local/sbin' ],
    user        => 'heat',
    refreshonly => true,
    logoutput   => 'on_failure',
  }

  File['db_sync_script'] ~> Exec['heat_db_sync']
  Package['heat-engine'] ~> Exec['heat_db_sync']
  Package['heat-api'] ~> Exec['heat_db_sync']

}
