$LOAD_PATH.push(File.join(File.dirname(__FILE__), '..', '..', '..'))
require 'puppet/provider/mysql'

Puppet::Type.type(:database).provide(
  :mysql,
  :parent => Puppet::Provider::Mysql,
) do

  desc "Manages MySQL database."

  defaultfor :kernel => 'Linux'

  commands :mysql      => 'mysql'
  commands :mysqladmin => 'mysqladmin'

  def self.instances
    mysql(connection_options, '-NBe', 'show databases').split("\n").collect do |name|
      new(:name => name)
    end
  end

  def create
    mysql(connection_options, '-NBe', "create database `#{@resource[:name]}` character set #{resource[:charset]}")
  end

  def destroy
    mysqladmin(connection_options, '-f', 'drop', @resource[:name])
  end

  def charset
    mysql(connection_options, '-NBe', "show create database `#{@resource[:name]}`").match(/.*?(\S+)\s\*\//)[1]
  end

  def charset=(value)
    mysql(connection_options, '-NBe', "alter database `#{@resource[:name]}` CHARACTER SET #{value}")
  end

  def exists?
    begin
      mysql(connection_options, '-NBe', 'show databases').match(/^#{@resource[:name]}$/)
    rescue => e
      debug(e.message)
      return nil
    end
  end

end

