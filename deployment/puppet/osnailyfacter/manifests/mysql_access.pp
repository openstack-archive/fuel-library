class osnailyfacter::mysql_access (
  $ensure = 'present',
  $user = 'root',
  $password = '',
  $host = 'localhost',
) {
  $file_path = "/root/.my.cnf"

  file { "mysql-access" :
    ensure  => $ensure,
    path    => $file_path,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('osnailyfacter/mysql.access.cnf.erb')
  }
}
