require File.join File.dirname(__FILE__), '../test_common.rb'

class HeatPostTest < Test::Unit::TestCase
  def test_mysql_connection_without_auth
    TestCommon::MySQL.no_auth
    assert TestCommon::MySQL.connection?, 'Cannot connect to MySQL without auth!'
  end

  def test_amqp_accessible
    assert TestCommon::AMQP.connection?, 'Cannot connect to AMQP server!'
  end
end
