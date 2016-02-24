require File.join File.dirname(__FILE__), '../test_common.rb'

class HeatPostTest < Test::Unit::TestCase

  def test_amqp_accessible
    assert TestCommon::AMQP.connection?, 'Cannot connect to AMQP server!'
  end

  def test_keystone_haproxy_backend_online
    assert TestCommon::HAProxy.backend_up?('keystone-1'), 'Keystone-1 backend is not up!'
    assert TestCommon::HAProxy.backend_up?('keystone-2'), 'Keystone-2 backend is not up!'
  end
end
