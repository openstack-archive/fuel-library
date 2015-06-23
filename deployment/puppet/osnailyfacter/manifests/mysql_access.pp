class osnailyfacter::mysql_access (
  $ensure = 'present',
  $user = 'root',
  $password = '',
  $host = 'localhost',
) {
  $default_file_path = '/root/.my.cnf'
  $host_file_path = "/root/${host}.my.cnf"

  file { "${host}-mysql-access" :
    ensure  => $ensure,
    path    => $host_file_path,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('osnailyfacter/mysql.access.cnf.erb')
  }

  if $ensure == 'present' {
    file { 'default-mysql-access-link' :
      ensure => 'symlink',
      path   => $default_file_path,
      target => $host_file_path,
    }
  }

}
