class mysql::password (
  $root_password = 'UNSET',
  $old_root_password = '',
  $etc_root_password = false,
  $config_file = $mysql::params::config_file,
) inherits mysql::params {

  if $root_password != 'UNSET' {

    case $old_root_password {
      '':      { $old_pw='' }
      default: { $old_pw="-p${old_root_password}" }
    }

    exec { 'set_mysql_rootpw':
      command   => "mysqladmin -u root ${old_pw} password ${root_password}",
      logoutput => true,
      unless    => "mysqladmin -u root -p${root_password} status > /dev/null",
      path      => '/usr/local/sbin:/usr/bin:/usr/local/bin',
      tries     => 10,
      try_sleep => 3,
    }

    if $etc_root_password {
      $password_file_path = '/etc/mysql/conf.d/password.cnf'
    } else {
      $password_file_path = '/root/.my.cnf'
    }

    file { 'mysql_password' :
      path    => $password_file_path,
      content => template('mysql/my.cnf.pass.erb'),
      mode    => '0640',
      owner   => 'mysql',
      group   => 'mysql',
    }

    Service <| title == 'mysql' |>  -> Exec['set_mysql_rootpw']
    Service <| title == 'mysql-service' |> -> Exec['set_mysql_rootpw']

    Exec['set_mysql_rootpw'] -> File['mysql_password']
    File <| title == $config_file |> -> File['mysql_password']
    File <| title == '/etc/my.cnf' |> -> File['mysql_password']
    File['mysql_password'] -> Database <| provider=='mysql' |>
    File['mysql_password'] -> Database_grant <| provider=='mysql' |>
    File['mysql_password'] -> Database_user <| provider=='mysql' |>

    Anchor <| title == 'galera' |> -> Class['mysql::password'] -> Anchor <| title == 'galera-done' |>
    Exec <| title == 'wait-for-synced-state' |> -> Exec['set_mysql_rootpw']
    Exec <| title == 'wait-initial-sync' |> -> Exec['set_mysql_rootpw']

  }

}
