require File.join File.dirname(__FILE__), '../test_common.rb'

class MuranoPreTest < Test::Unit::TestCase

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

  def test_haproxy_murano_backend_present
    assert TestCommon::HAProxy.backend_present?('murano'), 'No murano haproxy backend!'
  end

  def test_horizon_haproxy_backend_online
    assert TestCommon::HAProxy.backend_up?('horizon'), 'Horizon HAProxy backend is not up!'
  end

end
