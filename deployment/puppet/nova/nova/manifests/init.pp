class nova {
  class { 'puppet': }
  class {
    [
      'bzr',
      'git',
      'gcc',
      'extrapackages',
      # I may need to move python-mysqldb to elsewhere if it depends on mysql
      'python',
    ]:
  }
  class { 'mysql::server':
    mysql_root_pw => 'password',
  }
  #mysql::db { ['nova', 'glance']:}
  #class rabbitmq::server {
  #
  #  }
}
