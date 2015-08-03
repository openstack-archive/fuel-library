require File.join File.dirname(__FILE__), '../test_common.rb'

class SaharaPreTest < Test::Unit::TestCase

  def test_amqp_accessible
    assert TestCommon::AMQP.connection?, 'Cannot connect to AMQP server!'
  end

  def test_haproxy_sahara_backend_present
    assert TestCommon::HAProxy.backend_present?('sahara'), 'No sahara haproxy backend!'
  end

  def test_horizon_haproxy_backend_online
    assert TestCommon::HAProxy.backend_up?('horizon'), 'Horizon HAProxy backend is not up!'
  end

  def test_keystone_backend_online
    assert TestCommon::HAProxy.backend_up?('keystone-1'), 'Haproxy keystone-1 backend is down!'
    assert TestCommon::HAProxy.backend_up?('keystone-2'), 'Haproxy keystone-2 backend is down!'
  end
end
