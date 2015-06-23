Puppet::Type.type(:database).provide(:mysql) do

  desc "Manages MySQL database."

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
    mysql(defaults_file, '-NBe', "show databases").split("\n").collect do |name|
      new(:name => name)
    end
  end

  def create
    tries=10
    begin
        debug("Trying to create database #{@resource[:name]} ")
        mysql(defaults_file, '-NBe', "create database `#{@resource[:name]}` character set #{resource[:charset]}")
    rescue
        debug("Can't connect to the server: #{tries} tries to reconnect")
        sleep 5
        retry unless (tries -= 1) <= 0
    end
  end

  def destroy
    mysqladmin(defaults_file, '-f', 'drop', @resource[:name])
  end

  def charset
    mysql(defaults_file, '-NBe', "show create database `#{resource[:name]}`").match(/.*?(\S+)\s\*\//)[1]
  end

  def charset=(value)
    mysql(defaults_file, '-NBe', "alter database `#{resource[:name]}` CHARACTER SET #{value}")
  end

  def exists?
    begin
      mysql(defaults_file, '-NBe', "show databases").match(/^#{@resource[:name]}$/)
    rescue => e
      debug(e.message)
      return nil
    end
  end

end

