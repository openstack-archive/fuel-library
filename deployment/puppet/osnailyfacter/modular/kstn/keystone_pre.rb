require File.join File.dirname(__FILE__), '../test_common.rb'

PUBLIC_BACKEND = 'keystone-1'
ADMIN_BACKEND  = 'keystone-2'

class KeystonePreTest < Test::Unit::TestCase

  def test_haproxy_public_backend_present
    assert TestCommon::HAProxy.backend_present?(PUBLIC_BACKEND), "There is no '#{PUBLIC_BACKEND}' HAProxy backend!"
  end

  def test_haproxy_admin_backend_present
    assert TestCommon::HAProxy.backend_present?(ADMIN_BACKEND), "There is no '#{ADMIN_BACKEND}' HAProxy backend!"
  end

  def test_mysql_accessible_for_keystone
    TestCommon::MySQL.pass = TestCommon::Settings.keystone['db_password']
    TestCommon::MySQL.user = 'keystone'
    TestCommon::MySQL.host = TestCommon::Settings.management_vip
    TestCommon::MySQL.port = 3306
    TestCommon::MySQL.db = 'keystone'
    assert TestCommon::MySQL.connection?, 'Cannot connect to MySQL with Keystone auth!'
  end

  def test_amqp_accessible
    assert TestCommon::AMQP.connection?, 'Cannot connect to AMQP server!'
  end

end
