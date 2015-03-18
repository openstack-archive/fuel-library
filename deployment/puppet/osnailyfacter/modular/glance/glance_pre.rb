require File.join File.dirname(__FILE__), '../test_common.rb'

BACKEND = 'glance-api'

class GlancePreTest < Test::Unit::TestCase

  def test_haproxy_glance_backend_present
    assert TestCommon::HAProxy.backend_present?(BACKEND), "There is no '#{BACKEND}' HAProxy backend!"
  end

  def test_mysql_accessible_for_glance
    TestCommon::MySQL.pass = TestCommon::Settings.glance['db_password']
    TestCommon::MySQL.user = 'glance'
    TestCommon::MySQL.host = TestCommon::Settings.management_vip
    TestCommon::MySQL.port = 3306
    TestCommon::MySQL.db = 'glance'
    assert MySQL.connection?, 'Cannot connect to MySQL with Glance auth!'
  end

  def test_amqp_accessible
    user = TestCommon::Settings.rabbit['user']
    password = TestCommon::Settings.rabbit['password']
    host = TestCommon::Settings.management_vip
    assert TestCommon::AMQP.connection?(user, password, host), 'Cannot connect to AMQP server!'
  end

end
