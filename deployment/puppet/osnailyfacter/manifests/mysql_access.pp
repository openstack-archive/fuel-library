define osnailyfacter::mysql_access (
  $user,
  $password,
  $host,
) {
  $base_directory = '/etc'
  $file_name = "${name}-mysql-access.cnf"
  $file_path = "${base_directory}/${file_name}"

  file { "${name}-mysql-access" :
    ensure  => 'present',
    path    => $file_path,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('osnailyfacter/mysql.access.cnf.erb')
  }

  Database <||> {
    defaults_file => $file_path,
  }

  Database_grant <||> {
    defaults_file => $file_path,
  }

  Database_user <||> {
    defaults_file => $file_path,
  }
}
