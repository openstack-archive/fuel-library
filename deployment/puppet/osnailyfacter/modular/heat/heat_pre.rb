require File.join File.dirname(__FILE__), '../test_common.rb'

class HeatPostTest < Test::Unit::TestCase
  def test_mysql_connection_without_auth
    TestCommon::MySQL.no_auth
    assert TestCommon::MySQL.connection?, 'Cannot connect to MySQL without auth!'
  end

  def test_amqp_accessible
    user = TestCommon::Settings.rabbit['user']
    password = TestCommon::Settings.rabbit['password']
    host = TestCommon::Settings.management_vip
    assert TestCommon::AMQP.connection?(user, password, host), 'Cannot connect to AMQP server!'
  end
end
