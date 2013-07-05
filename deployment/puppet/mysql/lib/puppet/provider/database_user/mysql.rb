$LOAD_PATH.push(File.join(File.dirname(__FILE__), '..', '..', '..'))
require 'puppet/provider/mysql'
Puppet::Type.type(:database_user).provide(
    :mysql,
    :parent => Puppet::Provider::Mysql,
) do

  desc "manage users for a mysql database."

  defaultfor :kernel => 'Linux'

  commands :mysql      => 'mysql'
  commands :mysqladmin => 'mysqladmin'

  def self.instances
    users = mysql("mysql", mysql_cmd_string, '-BNe' "select concat(User, '@',Host) as User from mysql.user").split("\n")
    users.select{ |user| user =~ /.+@/ }.collect do |name|
      new(:name => name)
    end
  end

  def create
      mysql('mysql', connection_options, '-e', "create user '%s' identified by PASSWORD '%s'" % [ @resource[:name].sub("@", "'@'"), @resource.value(:password_hash) ])
  end

  def destroy
      mysql('mysql', connection_options, '-e', "drop user '%s'" % @resource.value(:name).sub("@", "'@'") )
  end

  def password_hash
      mysql('mysql', connection_options, '-NBe', "select password from user where CONCAT(user, '@', host) = '%s'" % @resource.value(:name)).chomp
  end

  def password_hash=(string)
      mysql("mysql", connection_options, '-e', "SET PASSWORD FOR '%s' = '%s'" % [ @resource[:name].sub("@", "'@'"), string ] )
  end

  def exists?
      not mysql('mysql', connection_options, '-NBe', "select '1' from user where CONCAT(user, '@', host) = '%s'" % @resource.value(:name)).empty?
  end

  def flush
    @property_hash.clear
    mysqladmin "flush-privileges"
  end
end
