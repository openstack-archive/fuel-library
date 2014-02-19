class keystone::db::cleanup_tokens(
  $db_type     = "mysql",
  $db_name     = "keystone",
  $db_user     = "root",
  $db_password = "root",
) {

  file { '/etc/cron.daily/cleanup-keystone-tokens.sh'
    content    => template('keystone/cleanup-keystone-tokens.sh.erb')
    owner      => 'root',
    group      => 'root',
    mode       => '0700',
  }

}
