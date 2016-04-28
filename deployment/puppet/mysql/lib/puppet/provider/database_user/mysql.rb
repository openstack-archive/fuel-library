Puppet::Type.type(:database_user).provide(:mysql) do

  desc "manage users for a mysql database."

  defaultfor :kernel => 'Linux'

  optional_commands :mysql      => 'mysql'

  # Optional defaults file
  def self.defaults_file
    if File.file?('/root/.my.cnf')
      "--defaults-extra-file=#{Facter.value(:root_home)}/.my.cnf"
    else
      nil
    end
  end

  def defaults_file
    self.class.defaults_file
  end

  def self.instances
    users = mysql(defaults_file, "mysql", '-BNe' "select concat(User, '@',Host) as User from mysql.user").split("\n")
    users.select{ |user| user =~ /.+@/ }.collect do |name|
      new(:name => name)
    end
  end

  def create
    mysql(defaults_file, "mysql", "-e", "create user '%s' identified by PASSWORD '%s'" % [ @resource[:name].sub("@", "'@'"), @resource.value(:password_hash) ])
  end

  def destroy
    mysql(defaults_file, "mysql", "-e", "drop user '%s'" % @resource.value(:name).sub("@", "'@'") )
  end

  def password_hash
    mysql(defaults_file, "mysql", "-NBe", "select password from user where CONCAT(user, '@', host) = '%s'" % @resource.value(:name)).chomp
  end

  def password_hash=(string)
    mysql(defaults_file, "mysql", "-e", "SET PASSWORD FOR '%s' = '%s'" % [ @resource[:name].sub("@", "'@'"), string ] )
  end

  def exists?
    tries=10
    begin
        not mysql(defaults_file, "mysql", "-NBe", "select '1' from user where CONCAT(user, '@', host) = '%s'" % @resource.value(:name)).empty?
    rescue
        debug("Can't connect to the mysql server: #{tries} tries to reconnect")
        sleep 5
        retry unless (tries -= 1) <= 0
    end
  end

end
