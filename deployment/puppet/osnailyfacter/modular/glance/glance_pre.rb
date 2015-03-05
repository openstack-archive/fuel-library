require File.join File.dirname(__FILE__), '../test_common.rb'
include TestCommon

BACKEND = 'glance-api'

class GlancePreTest < Test::Unit::TestCase

  def test_haproxy_glance_backend_present
    assert HAProxy.backend_present?(BACKEND), "There is no '#{BACKEND}' HAProxy backend!"
  end

  def test_mysql_accessible_for_glance
    MySQL.pass = Settings.glance['db_password']
    MySQL.user = 'glance'
    MySQL.host = Settings.management_vip
    MySQL.port = 3306
    MySQL.db = 'glance'
    assert MySQL.connection?, 'Cannot connect to MySQL with Glance auth!'
  end

  def test_amqp_accessible
    user = Settings.rabbit['user']
    password = Settings.rabbit['password']
    host = Settings.management_vip
    assert AMQP.connection?(user, password, host), 'Cannot connect to AMQP server!'
  end

end
