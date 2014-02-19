class keystone::db::cleanup_tokens(
  $db_type     = "mysql",
  $db_host     = "localhost",
  $db_name     = "keystone",
  $db_user     = "root",
  $db_password = "root",
) {

  if ( $db_type == "mysql" ) {
     package { "percona-toolkit":
       ensure => "installed",
     }
  }

  file { '/etc/cron.daily/cleanup-keystone-tokens.sh':
    content    => template('keystone/cleanup-keystone-tokens.sh.erb'),
    owner      => 'root',
    group      => 'root',
    mode       => '0700',
  }

}
