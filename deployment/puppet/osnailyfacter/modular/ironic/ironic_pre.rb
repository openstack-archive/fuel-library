require File.join File.dirname(__FILE__), '../test_common.rb'

class IronicPreTest < Test::Unit::TestCase

  def test_mysql_connection_without_auth
    TestCommon::MySQL.no_auth
      assert TestCommon::MySQL.connection?, 'Cannot connect to MySQL without auth!'
  end

  def test_amqp_accessible
    assert TestCommon::AMQP.connection?, 'Cannot connect to AMQP server!'
  end

  def test_haproxy_ironic_backend_present
    assert TestCommon::HAProxy.backend_present?('ironic'), 'No ironic haproxy backend!'
  end

end

