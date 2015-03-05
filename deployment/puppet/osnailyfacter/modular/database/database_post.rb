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
elsif Facts.osfamily == 'Debian'
  PACKAGES = %w(
  mysql-wsrep-common-5.6
  mysql-server-wsrep-core-5.6
  mysql-server-wsrep-5.6
  mysql-common
  mysql-client-core-5.6
  mysql-client-5.6
  libmysqlclient18
  )
else
  PACKAGES = []
end

class DatabaseInstallPostTest < Test::Unit::TestCase

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

  def test_mysql_connection_keystone
    MySQL.pass = Settings.keystone['db_password']
    MySQL.user = 'keystone'
    MySQL.host = Settings.management_vip
    MySQL.port = 3306
    assert MySQL.connection?, 'Cannot connect to MySQL with Keystone auth!'
  end

  def test_mysql_connection_glance
    MySQL.pass = Settings.glance['db_password']
    MySQL.user = 'glance'
    MySQL.host = Settings.management_vip
    MySQL.port = 3306
    assert MySQL.connection?, 'Cannot connect to MySQL with Glance auth!'
  end

  def test_mysql_connection_nova
    MySQL.pass = Settings.nova['db_password']
    MySQL.user = 'nova'
    MySQL.host = Settings.management_vip
    MySQL.port = 3306
    assert MySQL.connection?, 'Cannot connect to MySQL with Nova auth!'
  end

  def test_mysql_connection_cinder
    MySQL.pass = Settings.cinder['db_password']
    MySQL.user = 'cinder'
    MySQL.host = Settings.management_vip
    MySQL.port = 3306
    assert MySQL.connection?, 'Cannot connect to MySQL with Cinder auth!'
  end

  def test_mysql_connection_neutron
    return unless Settings.use_neutron
    MySQL.pass = Settings.cinder['db_password']
    MySQL.user = 'cinder'
    MySQL.host = Settings.management_vip
    MySQL.port = 3306
    assert MySQL.connection?, 'Cannot connect to MySQL with Cinder auth!'
  end

  def test_mysql_status_check_ok
    check_port = 49000
    url = "http://#{Settings.internal_address}:#{check_port}"
    assert Net.url_accessible?(url), 'Cannot connect to the MySQL Checker URL!'
  end

end
