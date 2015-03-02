require File.join File.dirname(__FILE__), '../test_common.rb'
include TestCommon

BACKEND = 'mysqld'
PROCESS = 'mysqld_safe'
PRIMITIVE = 'p_mysql'

if Facts.osfamily == 'RedHat'
  PACKAGES = %w(
  MySQL-server-wsrep
  MySQL-client-wsrep
  MySQL-shared
  mysql-libs
  )
end

class DatabasePostTest < Test::Unit::TestCase

  def test_packages_are_installed
    return unless PACKAGES
    PACKAGES.each do |package|
      assert Package.is_installed?(package), "Package '#{package}' is not installed!"
    end
  end

  def test_mysqld_safe_is_running
    assert PS.running?(PROCESS), "Process '#{PROCESS}' is not running!"
  end

  def test_mysql_primitive_running
    assert Pacemaker.primitive_started?(PRIMITIVE), "Primitive '#{PRIMITIVE}' is not started!"
  end

  def test_mysqld_haproxy_backend_up
    assert HAProxy.backend_up?(BACKEND), "HAProxy backend '#{BACKEND}' is not up!"
  end

  def test_mysql_connection_without_auth
    MySQL.no_auth
    assert MySQL.connection?, 'Cannot connect to MySQL without auth!'
  end

  def test_mysql_connection_with_auth
    MySQL.pass = Settings.mysql['root_password']
    MySQL.user = 'root'
    MySQL.host = 'localhost'
    MySQL.port = 3306
    assert MySQL.connection?, 'Cannot connect to MySQL with auth!'
  end

end
