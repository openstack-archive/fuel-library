require File.join File.dirname(__FILE__), '../test_common.rb'

BACKEND = 'mysqld'
PROCESS = 'mysqld_safe'
PRIMITIVE = 'p_mysql'

class DatabaseInstallPostTest < Test::Unit::TestCase

  def test_mysqld_safe_is_running
    assert TestCommon::Process.running?(PROCESS), "Process '#{PROCESS}' is not running!"
  end

  def test_mysql_primitive_running
    assert TestCommon::Pacemaker.primitive_started?(PRIMITIVE), "Primitive '#{PRIMITIVE}' is not started!"
  end

  def test_mysqld_haproxy_backend_up
    assert TestCommon::HAProxy.backend_up?(BACKEND), "HAProxy backend '#{BACKEND}' is not up!"
  end

  def test_mysql_connection_without_auth
    TestCommon::MySQL.no_auth
    assert TestCommon::MySQL.connection?, 'Cannot connect to MySQL without auth!'
  end

  def test_mysql_connection_with_auth
    TestCommon::MySQL.pass = TestCommon::Settings.mysql['root_password']
    TestCommon::MySQL.user = 'root'
    TestCommon::MySQL.host = 'localhost'
    TestCommon::MySQL.port = 3306
    assert TestCommon::MySQL.connection?, 'Cannot connect to MySQL with auth!'
  end

  def test_mysql_connection_keystone
    TestCommon::MySQL.pass = TestCommon::Settings.keystone['db_password']
    TestCommon::MySQL.user = 'keystone'
    TestCommon::MySQL.host = TestCommon::Settings.management_vip
    TestCommon::MySQL.port = 3306
    assert TestCommon::MySQL.connection?, 'Cannot connect to MySQL with Keystone auth!'
  end

  def test_mysql_connection_glance
    TestCommon::MySQL.pass = TestCommon::Settings.glance['db_password']
    TestCommon::MySQL.user = 'glance'
    TestCommon::MySQL.host = TestCommon::Settings.management_vip
    TestCommon::MySQL.port = 3306
    assert TestCommon::MySQL.connection?, 'Cannot connect to MySQL with Glance auth!'
  end

  def test_mysql_connection_nova
    TestCommon::MySQL.pass = TestCommon::Settings.nova['db_password']
    TestCommon::MySQL.user = 'nova'
    TestCommon::MySQL.host = TestCommon::Settings.management_vip
    TestCommon::MySQL.port = 3306
    assert TestCommon::MySQL.connection?, 'Cannot connect to MySQL with Nova auth!'
  end

  def test_mysql_connection_cinder
    TestCommon::MySQL.pass = TestCommon::Settings.cinder['db_password']
    TestCommon::MySQL.user = 'cinder'
    TestCommon::MySQL.host = TestCommon::Settings.management_vip
    TestCommon::MySQL.port = 3306
    assert TestCommon::MySQL.connection?, 'Cannot connect to MySQL with Cinder auth!'
  end

  def test_mysql_connection_neutron
    return unless TestCommon::Settings.use_neutron
    TestCommon::MySQL.pass = TestCommon::Settings.cinder['db_password']
    TestCommon::MySQL.user = 'cinder'
    TestCommon::MySQL.host = TestCommon::Settings.management_vip
    TestCommon::MySQL.port = 3306
    assert TestCommon::MySQL.connection?, 'Cannot connect to MySQL with Cinder auth!'
  end

  def test_mysql_status_check_ok
    check_port = 49000
    url = "http://#{TestCommon::Settings.internal_address}:#{check_port}"
    assert TestCommon::Network.url_accessible?(url), 'Cannot connect to the MySQL Checker URL!'
  end

end
