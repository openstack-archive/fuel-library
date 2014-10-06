module MySQL

  def drop_mysql_database(database)
    database.gsub! %q('), %q(")
    command = %Q(drop database `#{database}`)
    out,code = mysql_query command
    code == 0
  end

  def create_mysql_database(database)
    database.gsub! %q('), %q(")
    command = %Q(create database `#{database}` default character set utf8)
    out,code = mysql_query command
    code == 0
  end

  def mysql_query(query)
    query.gsub! %q('), %q(")
    command = %Q(mysql -Be '#{query}')
    out,code = run command
  end

  def mysql_database_exists?(database)
    database.gsub! %q('), %q(")
    command = %Q(show create database `#{database}`)
    out,code = mysql_query command
    code == 0
  end

  def mysql_dump(database, file)
    database.gsub! %q('), %q(")
    file.gsub! %q('), %q(")
    command = %Q(mysqldump --default-character-set=utf8 --single-transaction '#{database}' | gzip > '#{file}')
    out,code = run command
    code == 0
  end

  def mysql_restore(database, file)
    database.gsub! %q('), %q(")
    file.gsub! %q('), %q(")
    command = %Q(cat '#{file}' | gunzip | mysql --default-character-set=utf8 '#{database}')
    out,code = run command
    code == 0
  end

end