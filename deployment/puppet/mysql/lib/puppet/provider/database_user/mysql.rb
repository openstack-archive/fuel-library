Puppet::Type.type(:database_user).provide(:mysql) do

  desc "manage users for a mysql database."

  defaultfor :kernel => 'Linux'

  optional_commands :mysql      => 'mysql'
  optional_commands :mysqladmin => 'mysqladmin'

  def defaults_file
    if File.exists? @resource[:defaults_file]
      "--defaults-extra-file='#{@resource[:defaults_file]}'"
    else
      nil
    end
  end

  def self.instances
    users = mysql("mysql", defaults_file, '-BNe' "select concat(User, '@',Host) as User from mysql.user").split("\n")
    users.select{ |user| user =~ /.+@/ }.collect do |name|
      new(:name => name)
    end
  end

  def create
    mysql("mysql", defaults_file, "-e", "create user '%s' identified by PASSWORD '%s'" % [ @resource[:name].sub("@", "'@'"), @resource.value(:password_hash) ])
  end

  def destroy
    mysql("mysql", defaults_file, "-e", "drop user '%s'" % @resource.value(:name).sub("@", "'@'") )
  end

  def password_hash
    mysql("mysql", defaults_file, "-NBe", "select password from user where CONCAT(user, '@', host) = '%s'" % @resource.value(:name)).chomp
  end

  def password_hash=(string)
    mysql("mysql", defaults_file, "-e", "SET PASSWORD FOR '%s' = '%s'" % [ @resource[:name].sub("@", "'@'"), string ] )
  end

  def exists?
    tries=10
    begin
        not mysql("mysql", defaults_file, "-NBe", "select '1' from user where CONCAT(user, '@', host) = '%s'" % @resource.value(:name)).empty?
    rescue
        debug("Can't connect to the mysql server: #{tries} tries to reconnect")
        sleep 5
        retry unless (tries -= 1) <= 0
    end
  end

  def flush
    @property_hash.clear
    mysqladmin [ defaults_file, "flush-privileges" ]
  end

end
