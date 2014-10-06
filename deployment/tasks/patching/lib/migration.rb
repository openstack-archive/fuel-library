module Migration

  def recreate_murano_database
    database = 'murano'
    return false unless mysql_database_exists? database
    dump_file = File.join '/var/lib', "murano-database-dump-#{timestamp}.sql.gz"
    mysql_dump database, dump_file
    drop_mysql_database 'murano'
    create_mysql_database 'murano'
    run '/usr/bin/murano-manage --config-file=etc/murano/murano.conf db-sync'
    run '/usr/bin/murano-db-manage --config-file=/etc/murano/murano.conf upgrade'
  end

end